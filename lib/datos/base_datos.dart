import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../dominio/calculador_tomas.dart';
import '../servicios/fotos.dart';

/// Se incrementa cada vez que cambian los datos, para refrescar las pantallas.
final ValueNotifier<int> cambios = ValueNotifier<int>(0);

/// Tolerancia vigente antes de pasar una dosis a "no registrada".
Duration toleranciaActual = toleranciaPorDefecto;

late BaseDatos baseDatos;

class Medicamento {
  int? id;
  String nombre;
  String dosis;
  String via;
  int? cadaHoras;
  int? dias;
  DateTime? primeraToma;
  String nota;

  Medicamento({
    this.id,
    required this.nombre,
    this.dosis = '',
    this.via = 'Oral',
    this.cadaHoras,
    this.dias,
    this.primeraToma,
    this.nota = '',
  });

  /// Solo los horarios fijos generan avisos (versión 1).
  bool get tieneHorario =>
      cadaHoras != null && dias != null && primeraToma != null;

  List<DateTime> get horas => tieneHorario
      ? generarHorasDeToma(
          primeraToma: primeraToma!, cadaHoras: cadaHoras!, dias: dias!)
      : const [];

  String get titulo => dosis.isEmpty ? nombre : '$nombre $dosis';
}

class Receta {
  int? id;
  DateTime fecha;
  String clinica;
  String diagnostico;
  String? foto; // ruta de la foto de la receta, si la hay
  List<Medicamento> medicamentos;

  Receta({
    this.id,
    required this.fecha,
    this.clinica = '',
    required this.diagnostico,
    this.foto,
    List<Medicamento>? medicamentos,
  }) : medicamentos = medicamentos ?? [];

  bool activa(DateTime ahora) => medicamentos.any((m) =>
      m.tieneHorario &&
      !tratamientoTerminado(m.horas, ahora, tolerancia: toleranciaActual));
}

enum PosicionRango { bajo, dentro, alto }

/// Resultado de un examen de laboratorio (glucosa, colesterol, etc.).
class Examen {
  int? id;
  String nombre;
  double valor;
  String unidad;
  DateTime fecha;
  double? refMin; // rango de referencia que trae el informe
  double? refMax;
  String? foto;
  String nota;

  Examen({
    this.id,
    required this.nombre,
    required this.valor,
    this.unidad = '',
    required this.fecha,
    this.refMin,
    this.refMax,
    this.foto,
    this.nota = '',
  });

  /// Para agrupar el mismo examen escrito con distintas mayúsculas o espacios.
  String get clave => nombre.trim().toLowerCase();

  /// Posición respecto del rango del informe; null si el informe no trae rango.
  PosicionRango? get posicion {
    final min = refMin;
    final max = refMax;
    if (min == null && max == null) return null;
    if (min != null && valor < min) return PosicionRango.bajo;
    if (max != null && valor > max) return PosicionRango.alto;
    return PosicionRango.dentro;
  }
}

/// Una toma tal como se muestra en pantalla.
class TomaVista {
  final int id;
  final DateTime hora;
  final DateTime? registro;
  final String titulo;
  final String via;

  TomaVista(this.id, this.hora, this.registro, this.titulo, this.via);

  EstadoToma estado(DateTime ahora) => estadoDeToma(
        Toma(hora, horaRegistro: registro),
        ahora,
        tolerancia: toleranciaActual,
      );
}

/// Un aviso que hay que programar.
class AvisoPendiente {
  final int tomaId;
  final DateTime hora;
  final String titulo;
  final String via;
  AvisoPendiente(this.tomaId, this.hora, this.titulo, this.via);
}

class BaseDatos {
  BaseDatos._(this._db);
  final Database _db;

  static Future<BaseDatos> abrir() async {
    final ruta = p.join(await getDatabasesPath(), 'recetas.db');
    final db = await openDatabase(
      ruta,
      version: 3,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (d, antes, despues) async {
        if (antes < 2) {
          await d.execute('ALTER TABLE recetas ADD COLUMN foto TEXT');
        }
        if (antes < 3) await _crearTablaExamenes(d);
      },
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE recetas('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, fecha INTEGER NOT NULL, '
            'clinica TEXT NOT NULL, diagnostico TEXT NOT NULL, foto TEXT)');
        await d.execute('CREATE TABLE medicamentos('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'receta_id INTEGER NOT NULL REFERENCES recetas(id) ON DELETE CASCADE, '
            'nombre TEXT NOT NULL, dosis TEXT NOT NULL, via TEXT NOT NULL, '
            'cada_horas INTEGER, dias INTEGER, primera_toma INTEGER, '
            'nota TEXT NOT NULL)');
        await d.execute('CREATE TABLE tomas('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'medicamento_id INTEGER NOT NULL REFERENCES medicamentos(id) ON DELETE CASCADE, '
            'hora INTEGER NOT NULL, registro INTEGER)');
        await d.execute('CREATE INDEX idx_tomas_hora ON tomas(hora)');
        await d.execute(
            'CREATE TABLE ajustes(clave TEXT PRIMARY KEY, valor TEXT NOT NULL)');
        await _crearTablaExamenes(d);
      },
    );
    final bd = BaseDatos._(db);
    final minutos = await bd._leerAjuste('tolerancia_min');
    if (minutos != null) toleranciaActual = Duration(minutes: int.parse(minutos));
    return bd;
  }

  static Future<void> _crearTablaExamenes(DatabaseExecutor d) async {
    await d.execute('CREATE TABLE examenes('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL, '
        'valor REAL NOT NULL, unidad TEXT NOT NULL, fecha INTEGER NOT NULL, '
        'ref_min REAL, ref_max REAL, foto TEXT, nota TEXT NOT NULL)');
    await d.execute('CREATE INDEX idx_examenes_fecha ON examenes(fecha)');
  }

  Future<void> guardarExamen(Examen e) async {
    await _db.insert('examenes', {
      'nombre': e.nombre,
      'valor': e.valor,
      'unidad': e.unidad,
      'fecha': _ms(e.fecha),
      'ref_min': e.refMin,
      'ref_max': e.refMax,
      'foto': e.foto,
      'nota': e.nota,
    });
    cambios.value++;
  }

  Future<List<Examen>> examenes() async {
    final filas = await _db.query('examenes', orderBy: 'fecha DESC, id DESC');
    return filas
        .map((f) => Examen(
              id: f['id'] as int,
              nombre: f['nombre'] as String,
              valor: (f['valor'] as num).toDouble(),
              unidad: f['unidad'] as String,
              fecha: _fecha(f['fecha'] as int),
              refMin: (f['ref_min'] as num?)?.toDouble(),
              refMax: (f['ref_max'] as num?)?.toDouble(),
              foto: f['foto'] as String?,
              nota: f['nota'] as String,
            ))
        .toList();
  }

  Future<void> eliminarExamen(Examen e) async {
    await _db.delete('examenes', where: 'id = ?', whereArgs: [e.id]);
    await Fotos.borrar(e.foto);
    cambios.value++;
  }

  static int _ms(DateTime d) => d.millisecondsSinceEpoch;
  static DateTime _fecha(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

  Future<String?> _leerAjuste(String clave) async {
    final r = await _db.query('ajustes', where: 'clave = ?', whereArgs: [clave]);
    return r.isEmpty ? null : r.first['valor'] as String;
  }

  Future<void> guardarTolerancia(Duration d) async {
    toleranciaActual = d;
    await _db.insert(
      'ajustes',
      {'clave': 'tolerancia_min', 'valor': '${d.inMinutes}'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    cambios.value++;
  }

  /// Guarda la receta, crea sus tomas y devuelve los avisos por programar.
  Future<List<AvisoPendiente>> guardarReceta(Receta receta) async {
    final avisos = <AvisoPendiente>[];
    await _db.transaction((tx) async {
      final recetaId = await tx.insert('recetas', {
        'fecha': _ms(receta.fecha),
        'clinica': receta.clinica,
        'diagnostico': receta.diagnostico,
        'foto': receta.foto,
      });
      for (final m in receta.medicamentos) {
        final medId = await tx.insert('medicamentos', {
          'receta_id': recetaId,
          'nombre': m.nombre,
          'dosis': m.dosis,
          'via': m.via,
          'cada_horas': m.cadaHoras,
          'dias': m.dias,
          'primera_toma': m.primeraToma == null ? null : _ms(m.primeraToma!),
          'nota': m.nota,
        });
        for (final h in m.horas) {
          final tomaId =
              await tx.insert('tomas', {'medicamento_id': medId, 'hora': _ms(h)});
          avisos.add(AvisoPendiente(tomaId, h, m.titulo, m.via));
        }
      }
    });
    cambios.value++;
    return avisos;
  }

  static const _selectTomas =
      'SELECT t.id, t.hora, t.registro, m.nombre, m.dosis, m.via '
      'FROM tomas t JOIN medicamentos m ON m.id = t.medicamento_id ';

  List<TomaVista> _tomas(List<Map<String, Object?>> filas) => filas.map((f) {
        final dosis = f['dosis'] as String;
        final nombre = f['nombre'] as String;
        return TomaVista(
          f['id'] as int,
          _fecha(f['hora'] as int),
          f['registro'] == null ? null : _fecha(f['registro'] as int),
          dosis.isEmpty ? nombre : '$nombre $dosis',
          f['via'] as String,
        );
      }).toList();

  Future<List<TomaVista>> tomasEntre(DateTime desde, DateTime hasta) async =>
      _tomas(await _db.rawQuery(
          '${_selectTomas}WHERE t.hora >= ? AND t.hora < ? ORDER BY t.hora',
          [_ms(desde), _ms(hasta)]));

  Future<List<TomaVista>> historial(DateTime ahora) async =>
      _tomas(await _db.rawQuery(
          '${_selectTomas}WHERE t.hora < ? ORDER BY t.hora DESC LIMIT 500',
          [_ms(ahora)]));

  /// Tomas futuras sin registrar, para reprogramar avisos al abrir la app.
  Future<List<AvisoPendiente>> avisosFuturos(DateTime ahora) async {
    final filas = _tomas(await _db.rawQuery(
        '${_selectTomas}WHERE t.hora > ? AND t.registro IS NULL ORDER BY t.hora',
        [_ms(ahora)]));
    return filas
        .map((t) => AvisoPendiente(t.id, t.hora, t.titulo, t.via))
        .toList();
  }

  Future<void> marcarTomada(int tomaId, DateTime ahora) async {
    await _db.update('tomas', {'registro': _ms(ahora)},
        where: 'id = ?', whereArgs: [tomaId]);
    cambios.value++;
  }

  Future<List<Receta>> recetas() async {
    final filas = await _db.query('recetas', orderBy: 'fecha DESC, id DESC');
    final resultado = <Receta>[];
    for (final f in filas) {
      final meds = await _db.query('medicamentos',
          where: 'receta_id = ?', whereArgs: [f['id']], orderBy: 'id');
      resultado.add(Receta(
        id: f['id'] as int,
        fecha: _fecha(f['fecha'] as int),
        clinica: f['clinica'] as String,
        diagnostico: f['diagnostico'] as String,
        foto: f['foto'] as String?,
        medicamentos: meds
            .map((m) => Medicamento(
                  id: m['id'] as int,
                  nombre: m['nombre'] as String,
                  dosis: m['dosis'] as String,
                  via: m['via'] as String,
                  cadaHoras: m['cada_horas'] as int?,
                  dias: m['dias'] as int?,
                  primeraToma: m['primera_toma'] == null
                      ? null
                      : _fecha(m['primera_toma'] as int),
                  nota: m['nota'] as String,
                ))
            .toList(),
      ));
    }
    return resultado;
  }

  /// Elimina la receta y devuelve los ids de toma cuyos avisos hay que cancelar.
  Future<List<int>> eliminarReceta(int recetaId) async {
    final ids = (await _db.rawQuery(
      'SELECT t.id FROM tomas t JOIN medicamentos m ON m.id = t.medicamento_id '
      'WHERE m.receta_id = ?',
      [recetaId],
    ))
        .map((f) => f['id'] as int)
        .toList();
    final fotoFila =
        await _db.query('recetas', columns: ['foto'], where: 'id = ?', whereArgs: [recetaId]);
    await _db.delete('recetas', where: 'id = ?', whereArgs: [recetaId]);
    if (fotoFila.isNotEmpty) await Fotos.borrar(fotoFila.first['foto'] as String?);
    cambios.value++;
    return ids;
  }
}
