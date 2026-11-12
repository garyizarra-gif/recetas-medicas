import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import '../datos/base_datos.dart';
import '../servicios/avisos.dart';
import 'marca.dart';

class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _EstadoAjustes();
}

class _EstadoAjustes extends State<PantallaAjustes> {
  static const _paquete = 'pe.systemia.recetas_medicas';

  Future<void> _abrir(String accion, {String? datos}) async {
    try {
      await AndroidIntent(action: accion, data: datos).launch();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo abrir esa pantalla en tu celular.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes y ayuda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Que los avisos nunca fallen',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Algunos celulares (Xiaomi, Samsung, Huawei, Oppo) cierran las apps '
            'para ahorrar batería y los avisos dejan de sonar. Haz esto una vez:\n\n'
            '1. Permite las notificaciones y las alarmas exactas para esta app.\n'
            '2. En la batería de esta app, elige "Sin restricciones" o "No optimizar".\n'
            '3. Si tu celular tiene "Inicio automático", actívalo para esta app.\n'
            '4. Sube el volumen de notificaciones y quita el modo No molestar.\n\n'
            'Después usa la prueba para comprobar que suena.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _abrir('android.settings.APPLICATION_DETAILS_SETTINGS',
                datos: 'package:$_paquete'),
            icon: const Icon(Icons.settings),
            label: const Text('Abrir ajustes de la app'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                _abrir('android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'),
            icon: const Icon(Icons.battery_saver),
            label: const Text('Ajustes de batería'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await Avisos.pedirPermisos();
              await Avisos.probarEnUnMinuto();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Aviso de prueba en 1 minuto. Puedes cerrar la app y bloquear el celular.')));
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Probar un aviso en 1 minuto'),
          ),
          const Divider(height: 40),
          Text('Tiempo para marcar una dosis',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
              'Si no marcas "Tomado" pasado este tiempo, la dosis queda como "No registrada".'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: toleranciaActual.inMinutes,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 30, child: Text('30 minutos')),
              DropdownMenuItem(value: 60, child: Text('1 hora')),
              DropdownMenuItem(value: 120, child: Text('2 horas')),
              DropdownMenuItem(value: 180, child: Text('3 horas')),
            ],
            onChanged: (v) async {
              if (v != null) {
                await baseDatos.guardarTolerancia(Duration(minutes: v));
              }
            },
          ),
          const Divider(height: 40),
          const Text(
            'Esta app registra y recuerda lo que indica tu receta. No da '
            'recomendaciones médicas. Ante cualquier duda, consulta a tu médico.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          const MarcaSystemIA(),
        ],
      ),
    );
  }
}
