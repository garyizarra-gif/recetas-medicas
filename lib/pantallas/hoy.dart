import 'dart:async';

import 'package:flutter/material.dart';

import '../datos/base_datos.dart';
import '../dominio/calculador_tomas.dart';
import '../formato.dart';
import '../servicios/avisos.dart';

class PantallaHoy extends StatefulWidget {
  final VoidCallback alAgregar;
  const PantallaHoy({super.key, required this.alAgregar});

  @override
  State<PantallaHoy> createState() => _EstadoHoy();
}

class _EstadoHoy extends State<PantallaHoy> {
  List<TomaVista> _tomas = [];
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    cambios.addListener(_cargar);
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) => _cargar());
    _cargar();
  }

  @override
  void dispose() {
    cambios.removeListener(_cargar);
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    final h = DateTime.now();
    final inicio = DateTime(h.year, h.month, h.day);
    final r = await baseDatos.tomasEntre(
        inicio, inicio.add(const Duration(days: 1)));
    if (mounted) setState(() => _tomas = r);
  }

  Future<void> _marcar(TomaVista t) async {
    await baseDatos.marcarTomada(t.id, DateTime.now());
    await Avisos.cancelar(t.id);
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hoy, ${diaLargo(ahora)}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_tomas.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.medication_outlined, size: 48),
                  const SizedBox(height: 8),
                  const Text('No tienes tomas programadas para hoy.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: widget.alAgregar,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar receta'),
                  ),
                ],
              ),
            ),
          ),
        for (final t in _tomas) _TarjetaToma(toma: t, ahora: ahora, alMarcar: _marcar),
      ],
    );
  }
}

class _TarjetaToma extends StatelessWidget {
  final TomaVista toma;
  final DateTime ahora;
  final Future<void> Function(TomaVista) alMarcar;
  const _TarjetaToma(
      {required this.toma, required this.ahora, required this.alMarcar});

  @override
  Widget build(BuildContext context) {
    final estado = toma.estado(ahora);
    final esquema = Theme.of(context).colorScheme;
    final (icono, color, texto) = switch (estado) {
      EstadoToma.tomada => (
          Icons.check_circle,
          Colors.green.shade700,
          'Tomada ${horaTexto(toma.registro!)}'
        ),
      EstadoToma.noRegistrada => (
          Icons.help_outline,
          Colors.orange.shade800,
          'No registrada'
        ),
      EstadoToma.pendiente => (
          Icons.alarm,
          esquema.primary,
          toma.hora.isAfter(ahora) ? 'Próxima' : 'Ahora'
        ),
    };
    return Card(
      child: ListTile(
        leading: Icon(icono, color: color, size: 32),
        title: Text(toma.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${horaTexto(toma.hora)} · ${toma.via} · $texto'),
        trailing: estado == EstadoToma.tomada
            ? null
            : FilledButton(
                onPressed: () => alMarcar(toma),
                child: const Text('Tomado'),
              ),
      ),
    );
  }
}
