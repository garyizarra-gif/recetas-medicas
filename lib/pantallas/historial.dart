import 'package:flutter/material.dart';

import '../datos/base_datos.dart';
import '../dominio/calculador_tomas.dart';
import '../formato.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _EstadoHistorial();
}

class _EstadoHistorial extends State<PantallaHistorial> {
  List<TomaVista> _tomas = [];

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
    final r = await baseDatos.historial(DateTime.now());
    if (mounted) setState(() => _tomas = r);
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    if (_tomas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aún no hay tomas en el historial.',
              textAlign: TextAlign.center),
        ),
      );
    }
    final tomadas =
        _tomas.where((t) => t.estado(ahora) == EstadoToma.tomada).length;
    final noRegistradas =
        _tomas.where((t) => t.estado(ahora) == EstadoToma.noRegistrada).length;

    final hijos = <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Dato('$tomadas', 'Tomadas', Colors.green.shade700),
              _Dato('$noRegistradas', 'No registradas', Colors.orange.shade800),
            ],
          ),
        ),
      ),
    ];
    DateTime? diaActual;
    for (final t in _tomas) {
      if (diaActual == null || !mismoDia(diaActual, t.hora)) {
        diaActual = t.hora;
        hijos.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Text(diaLargo(t.hora),
              style: Theme.of(context).textTheme.titleSmall),
        ));
      }
      final estado = t.estado(ahora);
      final tomada = estado == EstadoToma.tomada;
      hijos.add(Card(
        child: ListTile(
          leading: Icon(
            tomada ? Icons.check_circle : Icons.help_outline,
            color: tomada ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          title: Text(t.titulo),
          subtitle: Text(
            '${horaTexto(t.hora)} · ${tomada ? 'Tomada ${horaTexto(t.registro!)}' : estado == EstadoToma.pendiente ? 'Pendiente' : 'No registrada'}',
          ),
        ),
      ));
    }
    return ListView(padding: const EdgeInsets.all(16), children: hijos);
  }
}

class _Dato extends StatelessWidget {
  final String numero;
  final String etiqueta;
  final Color color;
  const _Dato(this.numero, this.etiqueta, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(numero,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(etiqueta),
        ],
      );
}
