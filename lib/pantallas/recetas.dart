import 'dart:io';

import 'package:flutter/material.dart';

import '../datos/base_datos.dart';
import '../formato.dart';
import '../servicios/avisos.dart';
import '../servicios/fotos.dart';

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
              leading: Fotos.existe(r.foto)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(File(r.foto!),
                          width: 48, height: 48, fit: BoxFit.cover, cacheWidth: 120),
                    )
                  : const Icon(Icons.description_outlined, size: 40),
              title: Text(r.diagnostico,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${fechaCorta(r.fecha)}'
                '${r.clinica.isEmpty ? '' : ' · ${r.clinica}'}\n'
                '${r.medicamentos.map((m) => m.nombre).join(', ')}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receta'),
        actions: [
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
          if (Fotos.existe(receta.foto)) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PantallaFoto(ruta: receta.foto!))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(receta.foto!),
                    height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: Text('Toca la foto para verla completa y ampliarla.',
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
