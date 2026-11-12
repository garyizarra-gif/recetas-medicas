import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../datos/base_datos.dart';
import '../formato.dart';
import '../servicios/avisos.dart';
import '../servicios/fotos.dart';
import 'recetas.dart' show PantallaFoto;

/// Datos de un medicamento mientras se llena el formulario.
class _FormMedicamento {
  final nombre = TextEditingController();
  final dosis = TextEditingController();
  final via = TextEditingController(text: 'Oral');
  final cadaHoras = TextEditingController();
  final dias = TextEditingController();
  final nota = TextEditingController();
  DateTime primeraToma = _proximaHora();

  static DateTime _proximaHora() {
    final n = DateTime.now().add(const Duration(hours: 1));
    return DateTime(n.year, n.month, n.day, n.hour);
  }

  void liberar() {
    for (final c in [nombre, dosis, via, cadaHoras, dias, nota]) {
      c.dispose();
    }
  }
}

class PantallaNuevaReceta extends StatefulWidget {
  const PantallaNuevaReceta({super.key});

  @override
  State<PantallaNuevaReceta> createState() => _EstadoNuevaReceta();
}

class _EstadoNuevaReceta extends State<PantallaNuevaReceta> {
  final _formKey = GlobalKey<FormState>();
  final _clinica = TextEditingController();
  final _diagnostico = TextEditingController();
  DateTime _fecha = DateTime.now();
  final List<_FormMedicamento> _meds = [_FormMedicamento()];
  String? _foto;
  bool _guardada = false;

  Future<void> _tomarFoto(ImageSource fuente) async {
    try {
      final ruta = await Fotos.capturar(fuente);
      if (ruta == null || !mounted) return;
      await Fotos.borrar(_foto);
      setState(() => _foto = ruta);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir la cámara o la galería. Revisa los permisos.')));
    }
  }

  Future<void> _quitarFoto() async {
    await Fotos.borrar(_foto);
    if (mounted) setState(() => _foto = null);
  }

  @override
  void dispose() {
    // Si el usuario sale sin guardar, no dejamos la foto huérfana.
    if (!_guardada) Fotos.borrar(_foto);
    _clinica.dispose();
    _diagnostico.dispose();
    for (final m in _meds) {
      m.liberar();
    }
    super.dispose();
  }

  Future<void> _elegirFechaReceta() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _elegirPrimeraToma(_FormMedicamento m) async {
    final f = await showDatePicker(
      context: context,
      initialDate: m.primeraToma,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (f == null || !mounted) return;
    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(m.primeraToma),
    );
    if (h == null) return;
    setState(() => m.primeraToma = DateTime(f.year, f.month, f.day, h.hour, h.minute));
  }

  String? _entero(String? v, {required int min, required int max}) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < min || n > max) return 'Entre $min y $max';
    return null;
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    final meds = <Medicamento>[];
    for (final f in _meds) {
      final cada = int.tryParse(f.cadaHoras.text.trim());
      final dias = int.tryParse(f.dias.text.trim());
      final conHorario = cada != null && dias != null;
      meds.add(Medicamento(
        nombre: f.nombre.text.trim(),
        dosis: f.dosis.text.trim(),
        via: f.via.text.trim().isEmpty ? 'Oral' : f.via.text.trim(),
        cadaHoras: conHorario ? cada : null,
        dias: conHorario ? dias : null,
        primeraToma: conHorario ? f.primeraToma : null,
        nota: f.nota.text.trim(),
      ));
    }
    final receta = Receta(
      fecha: _fecha,
      clinica: _clinica.text.trim(),
      diagnostico: _diagnostico.text.trim(),
      foto: _foto,
      medicamentos: meds,
    );
    Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PantallaConfirmar(receta: receta),
    )).then((guardada) {
      if (guardada == true) {
        _guardada = true;
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva receta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _seccionFoto(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diagnostico,
              decoration: const InputDecoration(
                labelText: 'Diagnóstico o malestar',
                hintText: 'Ej.: conjuntivitis, gripe, dolor de cabeza',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Escribe el diagnóstico o malestar'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clinica,
              decoration: const InputDecoration(
                labelText: 'Clínica, EsSalud o MINSA (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _elegirFechaReceta,
              icon: const Icon(Icons.event),
              label: Text('Fecha de la receta: ${fechaCorta(_fecha)}'),
            ),
            const SizedBox(height: 20),
            Text('Medicamentos', style: Theme.of(context).textTheme.titleMedium),
            for (var i = 0; i < _meds.length; i++) _tarjetaMed(i),
            OutlinedButton.icon(
              onPressed: () => setState(() => _meds.add(_FormMedicamento())),
              icon: const Icon(Icons.add),
              label: const Text('Agregar otro medicamento'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _continuar,
              child: const Text('Revisar y confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionFoto() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto de la receta (opcional)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text(
                'Guárdala para no perderla. Luego completa los datos de abajo mirando la foto.'),
            const SizedBox(height: 8),
            if (_foto != null) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PantallaFoto(ruta: _foto!))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_foto!),
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _tomarFoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: Text(_foto == null ? 'Tomar foto' : 'Tomar otra'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _tomarFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
                if (_foto != null)
                  TextButton.icon(
                    onPressed: _quitarFoto,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Quitar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaMed(int i) {
    final m = _meds[i];
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Medicamento ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (_meds.length > 1)
                  IconButton(
                    tooltip: 'Quitar',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _meds.removeAt(i).liberar()),
                  ),
              ],
            ),
            TextFormField(
              controller: m.nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Escribe el nombre' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: m.dosis,
                    decoration: const InputDecoration(
                        labelText: 'Dosis', hintText: '500 mg'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: m.via,
                    decoration: const InputDecoration(labelText: 'Vía'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: m.cadaHoras,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cada (horas)'),
                    validator: (v) => _validarHorario(m, esCada: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: m.dias,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Por (días)'),
                    validator: (v) => _validarHorario(m, esCada: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _elegirPrimeraToma(m),
                icon: const Icon(Icons.alarm),
                label: Text('Primera toma: ${fechaHora(m.primeraToma)}'),
              ),
            ),
            TextFormField(
              controller: m.nota,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Indicación o nota (opcional)',
                helperText:
                    'Si no es un horario fijo (ej. "si hay dolor"), déjalo en nota: no tendrá aviso.',
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cada y días van juntos: o los dos (horario fijo) o ninguno (solo nota).
  String? _validarHorario(_FormMedicamento m, {required bool esCada}) {
    final cada = m.cadaHoras.text.trim();
    final dias = m.dias.text.trim();
    if (cada.isEmpty && dias.isEmpty) return null;
    return esCada
        ? _entero(cada, min: 1, max: 24)
        : _entero(dias, min: 1, max: 365);
  }
}

/// Paso de confirmación: nada se programa hasta que el usuario acepta.
class PantallaConfirmar extends StatefulWidget {
  final Receta receta;
  const PantallaConfirmar({super.key, required this.receta});

  @override
  State<PantallaConfirmar> createState() => _EstadoConfirmar();
}

class _EstadoConfirmar extends State<PantallaConfirmar> {
  bool _guardando = false;

  Future<void> _confirmar() async {
    setState(() => _guardando = true);
    final avisos = await baseDatos.guardarReceta(widget.receta);
    await Avisos.pedirPermisos();
    await Avisos.programarTodos(avisos);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(avisos.isEmpty
          ? 'Receta guardada.'
          : 'Receta guardada. ${avisos.length} avisos programados.'),
    ));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receta;
    final total = r.medicamentos.fold<int>(0, (s, m) => s + m.horas.length);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirma tu receta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
              'Revisa que todo coincida con tu receta. Los avisos se activan solo cuando confirmes.'),
          const SizedBox(height: 12),
          Text(r.diagnostico, style: Theme.of(context).textTheme.titleLarge),
          Text('${fechaCorta(r.fecha)}'
              '${r.clinica.isEmpty ? '' : ' · ${r.clinica}'}'),
          const SizedBox(height: 12),
          if (r.foto != null && Fotos.existe(r.foto)) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(r.foto!),
                  height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
          ],
          for (final m in r.medicamentos)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.titulo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('Vía: ${m.via}'),
                    const SizedBox(height: 4),
                    if (m.tieneHorario) ...[
                      Text('Cada ${m.cadaHoras} horas por ${m.dias} días'),
                      Text('${m.horas.length} tomas: '
                          '${m.horas.take(3).map(horaTexto).join(', ')}'
                          '${m.horas.length > 3 ? '…' : ''}'),
                      Text('Desde ${fechaHora(m.horas.first)} hasta '
                          '${fechaHora(m.horas.last)}'),
                    ] else
                      const Text('Sin aviso: se guarda solo como nota.',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    if (m.nota.isNotEmpty) Text('Nota: ${m.nota}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text('Se programarán $total avisos.',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _guardando ? null : _confirmar,
            child: const Text('Confirmar y activar avisos'),
          ),
          TextButton(
            onPressed: _guardando ? null : () => Navigator.pop(context, false),
            child: const Text('Corregir'),
          ),
        ],
      ),
    );
  }
}
