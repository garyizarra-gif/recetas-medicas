import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Adjuntos de recetas y exámenes (fotos y PDF): se guardan en la memoria
/// privada de la app.
class Fotos {
  Fotos._();

  static final _picker = ImagePicker();
  static int _contador = 0;

  static Future<String> _nuevaRuta(String extension) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'fotos_recetas'));
    await dir.create(recursive: true);
    // El contador evita choques cuando se guardan varios archivos en el mismo milisegundo.
    final nombre = '${DateTime.now().millisecondsSinceEpoch}_${_contador++}$extension';
    return p.join(dir.path, nombre);
  }

  /// Abre la cámara o la galería y devuelve la ruta de la copia guardada,
  /// o null si el usuario cancela.
  static Future<String?> capturar(ImageSource fuente) async {
    final x = await _picker.pickImage(
      source: fuente,
      maxWidth: 2200,
      imageQuality: 85,
    );
    if (x == null) return null;
    final ruta = await _nuevaRuta('.jpg');
    await x.saveTo(ruta);
    return ruta;
  }

  /// Galería con selección de varias fotos a la vez.
  static Future<List<String>> galeriaVarias() async {
    final lista = await _picker.pickMultiImage(maxWidth: 2200, imageQuality: 85);
    final rutas = <String>[];
    for (final x in lista) {
      final ruta = await _nuevaRuta('.jpg');
      await x.saveTo(ruta);
      rutas.add(ruta);
    }
    return rutas;
  }

  /// Elige uno o varios PDF y devuelve las rutas de las copias guardadas.
  static Future<List<String>> elegirPdfs() async {
    final elegidos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final rutas = <String>[];
    for (final f in elegidos) {
      final ruta = await _nuevaRuta('.pdf');
      final origen = f.path;
      if (origen != null) {
        await File(origen).copy(ruta);
      } else {
        await File(ruta).writeAsBytes(await f.readAsBytes());
      }
      rutas.add(ruta);
    }
    return rutas;
  }

  static bool esPdf(String ruta) => ruta.toLowerCase().endsWith('.pdf');

  /// Abre el PDF con el lector instalado en el celular.
  /// Devuelve false si no hay ninguna app que lo pueda abrir.
  static Future<bool> abrirPdf(String ruta) async {
    final r = await OpenFilex.open(ruta, type: 'application/pdf');
    return r.type == ResultType.done;
  }

  static Future<void> borrar(String? ruta) async {
    if (ruta == null) return;
    try {
      final f = File(ruta);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<void> borrarVarias(Iterable<String> rutas) async {
    for (final r in rutas) {
      await borrar(r);
    }
  }

  static bool existe(String? ruta) => ruta != null && File(ruta).existsSync();
}
