import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../datos/base_datos.dart';
import '../formato.dart';
import '../servicios/fotos.dart';
import 'recetas.dart' show PantallaFoto;

const _sugerencias = [
  'Glucosa',
  'Colesterol total',
  'Colesterol HDL',
  'Colesterol LDL',
  'Triglicéridos',
  'Hemoglobina',
  'Creatinina',
  'Ácido úrico',
];

class PantallaNuevoExamen extends StatefulWidget {
  /// Nombre ya elegido (al agregar otro resultado de un examen existente).
  final String? nombreInicial;
  final String? unidadInicial;
  const PantallaNuevoExamen({super.key, this.nombreInicial, this.unidadInicial});

  @override
  State<PantallaNuevoExamen> createState() => _EstadoNuevoExamen();
}

class _EstadoNuevoExamen extends State<PantallaNuevoExamen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.nombreInicial ?? '');
  final _valor = TextEditingController();
  late final _unidad =
      TextEditingController(text: widget.unidadInicial ?? 'mg/dL');
  final _refMin = TextEditingController();
  final _refMax = TextEditingController();
  final _nota = TextEditingController();
  DateTime _fecha = DateTime.now();
  String? _foto;
  bool _guardado = false;

  @override
  void dispose() {
    if (!_guardado) Fotos.borrar(_foto);
    for (final c in [_nombre, _valor, _unidad, _refMin, _refMax, _nota]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _numero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  String? _validarNumero(String? v, {bool obligatorio = false}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return obligatorio ? 'Escribe el valor' : null;
    return _numero(t) == null ? 'Número no válido' : null;
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (f != null) setState(() => _fecha = f);
  }

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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final min = _numero(_refMin.text);
    final max = _numero(_refMax.text);
    if (min != null && max != null && min > max) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('El rango mínimo no puede ser mayor que el máximo.')));
      return;
    }
    await baseDatos.guardarExamen(Examen(
      nombre: _nombre.text.trim(),
      valor: _numero(_valor.text)!,
      unidad: _unidad.text.trim(),
      fecha: _fecha,
      refMin: min,
      refMax: max,
      foto: _foto,
      nota: _nota.text.trim(),
    ));
    _guardado = true;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo resultado')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.nombreInicial == null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in _sugerencias)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() => _nombre.text = s),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nombre,
              readOnly: widget.nombreInicial != null,
              decoration: const InputDecoration(
                labelText: 'Examen',
                hintText: 'Ej.: Glucosa',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Escribe el nombre del examen' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _valor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Resultado', border: OutlineInputBorder()),
                    validator: (v) => _validarNumero(v, obligatorio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unidad,
                    decoration: const InputDecoration(
                        labelText: 'Unidad', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _elegirFecha,
              icon: const Icon(Icons.event),
              label: Text('Fecha del examen: ${fechaCorta(_fecha)}'),
            ),
            const SizedBox(height: 16),
            Text('Rango de referencia del informe (opcional)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text(
                'Cópialo tal como aparece en tu informe, para marcar si el resultado está dentro o fuera.'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _refMin,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Mínimo', border: OutlineInputBorder()),
                    validator: _validarNumero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _refMax,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Máximo', border: OutlineInputBorder()),
                    validator: _validarNumero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto del informe (opcional)',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (_foto != null) ...[
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PantallaFoto(ruta: _foto!))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_foto!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover),
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
                            onPressed: () async {
                              await Fotos.borrar(_foto);
                              if (mounted) setState(() => _foto = null);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Quitar'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nota,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Nota (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _guardar, child: const Text('Guardar resultado')),
          ],
        ),
      ),
    );
  }
}
