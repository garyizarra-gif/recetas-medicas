import 'dart:io';

import 'package:flutter/material.dart';

import '../datos/base_datos.dart';
import '../formato.dart';
import '../servicios/avisos.dart';
import '../servicios/fotos.dart';
import 'nueva_receta.dart' show PantallaNuevaReceta;

/// Foto de la receta a pantalla completa, con zoom.
class PantallaFoto extends StatelessWidget {
  final String ruta;
  const PantallaFoto({super.key, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto de la receta'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          child: Image.file(File(ruta)),
        ),
      ),
    );
  }
}

/// Varias fotos de un mismo caso: se pasa de una a otra deslizando.
class PantallaFotos extends StatefulWidget {
  final List<String> rutas;
  final int inicial;
  const PantallaFotos({super.key, required this.rutas, this.inicial = 0});

  @override
  State<PantallaFotos> createState() => _EstadoFotos();
}

class _EstadoFotos extends State<PantallaFotos> {
  late final PageController _control =
      PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.rutas.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(total == 1 ? 'Foto de la receta' : 'Foto ${_actual + 1} de $total'),
      ),
      body: PageView.builder(
        controller: _control,
        itemCount: total,
        onPageChanged: (i) => setState(() => _actual = i),
        itemBuilder: (_, i) => Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            child: Image.file(File(widget.rutas[i])),
          ),
        ),
      ),
    );
  }
}

/// Miniaturas de las fotos y PDF de una receta. Con [onQuitar] muestra una
/// "x" para quitar cada adjunto (al editar).
class TiraAdjuntos extends StatelessWidget {
  final List<String> rutas;
  final void Function(String ruta)? onQuitar;
  const TiraAdjuntos({super.key, required this.rutas, this.onQuitar});

  Future<void> _abrir(BuildContext context, String ruta) async {
    if (Fotos.esPdf(ruta)) {
      final ok = await Fotos.abrirPdf(ruta);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No hay una app instalada para abrir PDF.')));
      }
      return;
    }
    final fotos = rutas.where((r) => !Fotos.esPdf(r) && Fotos.existe(r)).toList();
    final i = fotos.indexOf(ruta);
    if (i < 0) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PantallaFotos(rutas: fotos, inicial: i)));
  }

  @override
  Widget build(BuildContext context) {
    var numeroPdf = 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final r in rutas)
          Builder(builder: (context) {
            final pdf = Fotos.esPdf(r);
            if (pdf) numeroPdf++;
            final Widget contenido = !Fotos.existe(r)
                ? const Center(child: Icon(Icons.broken_image_outlined))
                : pdf
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf,
                              size: 36, color: Colors.red),
                          Text('PDF $numeroPdf',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      )
                    : Image.file(File(r),
                        width: 96, height: 96, fit: BoxFit.cover, cacheWidth: 260);
            return SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      onTap: () => _abrir(context, r),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: contenido,
                        ),
                      ),
                    ),
                  ),
                  if (onQuitar != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => onQuitar!(r),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class PantallaRecetas extends StatefulWidget {
  const PantallaRecetas({super.key});

  @override
  State<PantallaRecetas> createState() => _EstadoRecetas();
}

class _EstadoRecetas extends State<PantallaRecetas> {
  List<Receta> _recetas = [];
  String _filtro = '';

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
    final r = await baseDatos.recetas();
    if (mounted) setState(() => _recetas = r);
  }

  bool _coincide(Receta r) {
    if (_filtro.isEmpty) return true;
    final f = _filtro.toLowerCase();
    return r.diagnostico.toLowerCase().contains(f) ||
        r.clinica.toLowerCase().contains(f) ||
        r.medicamentos.any((m) => m.nombre.toLowerCase().contains(f));
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final visibles = _recetas.where(_coincide).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar por diagnóstico, clínica o medicamento',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _filtro = v.trim()),
        ),
        const SizedBox(height: 12),
        if (_recetas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aquí quedarán guardadas tus recetas, para que no se pierdan y '
              'puedas mostrarlas a tu médico.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final r in visibles)
          Card(
            child: ListTile(
              leading: r.portada != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(File(r.portada!),
                          width: 48, height: 48, fit: BoxFit.cover, cacheWidth: 120),
                    )
                  : Icon(
                      r.adjuntos.any(Fotos.esPdf)
                          ? Icons.picture_as_pdf
                          : Icons.description_outlined,
                      size: 40),
              title: Text(r.diagnostico,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${fechaCorta(r.fecha)}'
                '${r.clinica.isEmpty ? '' : ' · ${r.clinica}'}\n'
                '${r.medicamentos.map((m) => m.nombre).join(', ')}'
                '${r.adjuntos.length > 1 ? '\n${r.adjuntos.length} adjuntos' : ''}',
              ),
              isThreeLine: true,
              trailing: Chip(
                label: Text(r.activa(ahora) ? 'Activa' : 'Terminada'),
                visualDensity: VisualDensity.compact,
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PantallaDetalleReceta(receta: r),
              )),
            ),
          ),
      ],
    );
  }
}

class PantallaDetalleReceta extends StatelessWidget {
  final Receta receta;
  const PantallaDetalleReceta({super.key, required this.receta});

  Future<void> _eliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar esta receta?'),
        content: const Text(
            'Se borrarán también su historial de tomas y sus avisos.'),
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
    if (ok != true) return;
    final ids = await baseDatos.eliminarReceta(receta.id!);
    await Avisos.cancelarVarios(ids);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _editar(BuildContext context) async {
    final guardada = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => PantallaNuevaReceta(receta: receta)));
    // Esta pantalla muestra la receta anterior: al guardar, se vuelve a la lista.
    if (guardada == true && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receta'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editar(context),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _eliminar(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(receta.diagnostico,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${fechaCorta(receta.fecha)}'
              '${receta.clinica.isEmpty ? '' : ' · ${receta.clinica}'}'),
          const SizedBox(height: 16),
          if (receta.adjuntos.isNotEmpty) ...[
            TiraAdjuntos(rutas: receta.adjuntos),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                  'Toca una foto para verla completa y ampliarla; toca un PDF para abrirlo.',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
          for (final m in receta.medicamentos)
            Card(
              child: ListTile(
                title: Text(m.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text([
                  'Vía: ${m.via}',
                  if (m.tieneHorario)
                    'Cada ${m.cadaHoras} h por ${m.dias} días, desde ${fechaHora(m.primeraToma!)}'
                  else
                    'Sin aviso (indicación en nota)',
                  if (m.nota.isNotEmpty) 'Nota: ${m.nota}',
                ].join('\n')),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }
}
