import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Fotos de recetas: se guardan en la memoria privada de la app.
class Fotos {
  Fotos._();

  static final _picker = ImagePicker();

  /// Abre la cámara o la galería y devuelve la ruta de la copia guardada,
  /// o null si el usuario cancela.
  static Future<String?> capturar(ImageSource fuente) async {
    final x = await _picker.pickImage(
      source: fuente,
      maxWidth: 2200,
      imageQuality: 85,
    );
    if (x == null) return null;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'fotos_recetas'));
    await dir.create(recursive: true);
    final ruta = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await x.saveTo(ruta);
    return ruta;
  }

  static Future<void> borrar(String? ruta) async {
    if (ruta == null) return;
    try {
      final f = File(ruta);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static bool existe(String? ruta) => ruta != null && File(ruta).existsSync();
}
