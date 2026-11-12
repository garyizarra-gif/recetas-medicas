import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../datos/base_datos.dart';
import '../formato.dart';
import '../servicios/fotos.dart';
import 'nuevo_examen.dart';
import 'recetas.dart' show PantallaFoto;

Color _colorPosicion(PosicionRango? p) => switch (p) {
      PosicionRango.dentro => Colors.green.shade700,
      PosicionRango.bajo || PosicionRango.alto => Colors.orange.shade800,
      null => Colors.blueGrey,
    };

String _textoPosicion(PosicionRango? p) => switch (p) {
      PosicionRango.dentro => 'Dentro del rango del informe',
      PosicionRango.bajo => 'Por debajo del rango del informe',
      PosicionRango.alto => 'Por encima del rango del informe',
      null => 'Sin rango en el informe',
    };

String _rangoTexto(Examen e) {
  if (e.refMin == null && e.refMax == null) return '';
  if (e.refMin != null && e.refMax != null) {
    return 'Rango: ${numTexto(e.refMin!)} – ${numTexto(e.refMax!)} ${e.unidad}';
  }
  if (e.refMax != null) return 'Rango: hasta ${numTexto(e.refMax!)} ${e.unidad}';
  return 'Rango: desde ${numTexto(e.refMin!)} ${e.unidad}';
}

class PantallaExamenes extends StatefulWidget {
  const PantallaExamenes({super.key});

  @override
  State<PantallaExamenes> createState() => _EstadoExamenes();
}

class _EstadoExamenes extends State<PantallaExamenes> {
  List<Examen> _todos = [];

  @override
  void initState() {
    super.initState();
    cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final r = await baseDatos.examenes();
    if (mounted) setState(() => _todos = r);
  }

  @override
  Widget build(BuildContext context) {
    if (_todos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aquí guardas los resultados de glucosa, colesterol, triglicéridos '
            'y otros exámenes, y ves cómo evolucionan.\n\n'
            'Toca "Nuevo resultado" para empezar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Agrupa por examen; _todos viene del más reciente al más antiguo.
    final grupos = <String, List<Examen>>{};
    for (final e in _todos) {
      grupos.putIfAbsent(e.clave, () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final lista in grupos.values)
          Card(
            child: ListTile(
              title: Text(lista.first.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${fechaCorta(lista.first.fecha)} · ${lista.length} '
                '${lista.length == 1 ? 'resultado' : 'resultados'}\n'
                '${_textoPosicion(lista.first.posicion)}',
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    numTexto(lista.first.valor),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _colorPosicion(lista.first.posicion),
                    ),
                  ),
                  Text(lista.first.unidad, style: const TextStyle(fontSize: 12)),
                ],
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PantallaDetalleExamen(clave: lista.first.clave),
              )),
            ),
          ),
      ],
    );
  }
}

class PantallaDetalleExamen extends StatefulWidget {
  final String clave;
  const PantallaDetalleExamen({super.key, required this.clave});

  @override
  State<PantallaDetalleExamen> createState() => _EstadoDetalleExamen();
}

class _EstadoDetalleExamen extends State<PantallaDetalleExamen> {
  List<Examen> _lista = []; // más reciente primero

  @override
  void initState() {
    super.initState();
    cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final todos = await baseDatos.examenes();
    final lista = todos.where((e) => e.clave == widget.clave).toList();
    if (!mounted) return;
    if (lista.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _lista = lista);
  }

  Future<void> _eliminar(Examen e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar este resultado?'),
        content: Text('${e.nombre}: ${numTexto(e.valor)} ${e.unidad} '
            'del ${fechaCorta(e.fecha)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) await baseDatos.eliminarExamen(e);
  }

  @override
  Widget build(BuildContext context) {
    if (_lista.isEmpty) return const Scaffold(body: SizedBox());
    final ultimo = _lista.first;
    final cronologico = _lista.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text(ultimo.nombre)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PantallaNuevoExamen(
              nombreInicial: ultimo.nombre, unidadInicial: ultimo.unidad),
        )),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo resultado'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text('Evolución', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (cronologico.length < 2)
            const Text(
                'Agrega otro resultado de este examen en otra fecha para ver la evolución.')
          else
            SizedBox(
              height: 210,
              child: CustomPaint(
                size: Size.infinite,
                painter: _PintorEvolucion(
                  puntos: cronologico,
                  linea: Theme.of(context).colorScheme.primary,
                  texto: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          if (cronologico.length >= 2 && _rangoTexto(ultimo).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Banda verde: ${_rangoTexto(ultimo)} (del último informe)',
                  style: const TextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 16),
          Text('Resultados', style: Theme.of(context).textTheme.titleMedium),
          for (final e in _lista)
            Card(
              child: ListTile(
                title: Text(
                  '${numTexto(e.valor)} ${e.unidad}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _colorPosicion(e.posicion),
                  ),
                ),
                subtitle: Text([
                  fechaCorta(e.fecha),
                  _textoPosicion(e.posicion),
                  if (_rangoTexto(e).isNotEmpty) _rangoTexto(e),
                  if (e.nota.isNotEmpty) 'Nota: ${e.nota}',
                ].join('\n')),
                isThreeLine: true,
                leading: Fotos.existe(e.foto)
                    ? GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PantallaFoto(ruta: e.foto!))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(e.foto!),
                              width: 44, height: 44, fit: BoxFit.cover, cacheWidth: 110),
                        ),
                      )
                    : null,
                trailing: IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _eliminar(e),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gráfico de línea simple: puntos en orden cronológico y banda del rango.
class _PintorEvolucion extends CustomPainter {
  final List<Examen> puntos;
  final Color linea;
  final Color texto;
  _PintorEvolucion(
      {required this.puntos, required this.linea, required this.texto});

  void _etiqueta(Canvas c, String t, Offset pos, {bool derecha = false}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: 11, color: texto)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, derecha ? Offset(pos.dx - tp.width, pos.dy) : pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const izq = 46.0, der = 14.0, arriba = 12.0, abajo = 26.0;
    final w = size.width - izq - der;
    final h = size.height - arriba - abajo;
    final ultimo = puntos.last;

    var lo = puntos.map((p) => p.valor).reduce(math.min);
    var hi = puntos.map((p) => p.valor).reduce(math.max);
    if (ultimo.refMin != null) lo = math.min(lo, ultimo.refMin!);
    if (ultimo.refMax != null) hi = math.max(hi, ultimo.refMax!);
    if (lo == hi) {
      lo -= 1;
      hi += 1;
    }
    final margen = (hi - lo) * 0.1;
    lo -= margen;
    hi += margen;

    double x(int i) => izq + w * i / (puntos.length - 1);
    double y(double v) => arriba + h * (1 - (v - lo) / (hi - lo));

    // Banda del rango de referencia.
    if (ultimo.refMin != null || ultimo.refMax != null) {
      final yAlto = y(ultimo.refMax ?? hi);
      final yBajo = y(ultimo.refMin ?? lo);
      canvas.drawRect(
        Rect.fromLTRB(izq, yAlto, izq + w, yBajo),
        Paint()..color = Colors.green.withValues(alpha: 0.15),
      );
    }

    // Ejes y valores extremos.
    final eje = Paint()
      ..color = texto.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(izq, arriba), Offset(izq, arriba + h), eje);
    canvas.drawLine(Offset(izq, arriba + h), Offset(izq + w, arriba + h), eje);
    _etiqueta(canvas, numTexto(double.parse(hi.toStringAsFixed(1))),
        Offset(izq - 4, arriba - 6), derecha: true);
    _etiqueta(canvas, numTexto(double.parse(lo.toStringAsFixed(1))),
        Offset(izq - 4, arriba + h - 6), derecha: true);
    _etiqueta(canvas, fechaCorta(puntos.first.fecha), Offset(izq, arriba + h + 6));
    _etiqueta(canvas, fechaCorta(ultimo.fecha),
        Offset(izq + w, arriba + h + 6), derecha: true);

    // Línea y puntos.
    final trazo = Paint()
      ..color = linea
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final ruta = Path();
    for (var i = 0; i < puntos.length; i++) {
      final o = Offset(x(i), y(puntos[i].valor));
      i == 0 ? ruta.moveTo(o.dx, o.dy) : ruta.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(ruta, trazo);
    for (var i = 0; i < puntos.length; i++) {
      final p = puntos[i];
      final o = Offset(x(i), y(p.valor));
      canvas.drawCircle(o, 5, Paint()..color = _colorPosicion(p.posicion));
      _etiqueta(canvas, numTexto(p.valor), Offset(o.dx - 8, o.dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _PintorEvolucion old) =>
      old.puntos != puntos || old.linea != linea || old.texto != texto;
}
