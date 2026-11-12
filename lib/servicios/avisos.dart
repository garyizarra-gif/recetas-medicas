import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../datos/base_datos.dart';

/// Avisos de toma: programados en el sistema, no dependen de internet
/// y sobreviven al reinicio del celular.
class Avisos {
  Avisos._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const int idPrueba = 2147483000;

  static final NotificationDetails _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'tomas',
      'Horas de toma',
      channelDescription: 'Recordatorios para tomar tus medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 600, 300, 600, 300, 600]),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
  );

  static Future<void> iniciar() async {
    tzdata.initializeTimeZones();
    // Perú no tiene horario de verano: una sola zona horaria.
    tz.setLocalLocation(tz.getLocation('America/Lima'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await pedirPermisos();
  }

  static Future<void> pedirPermisos() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static Future<void> programar(AvisoPendiente a) => _programar(
        a.tomaId,
        a.hora,
        'Hora de tu medicamento',
        '${a.titulo} · ${a.via}',
      );

  static Future<void> _programar(
      int id, DateTime hora, String titulo, String cuerpo) async {
    if (!hora.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: titulo,
      body: cuerpo,
      scheduledDate: tz.TZDateTime.from(hora, tz.local),
      notificationDetails: _detalles,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> programarTodos(Iterable<AvisoPendiente> avisos) async {
    for (final a in avisos) {
      await programar(a);
    }
  }

  static Future<void> cancelar(int tomaId) => _plugin.cancel(id: tomaId);

  static Future<void> cancelarVarios(Iterable<int> ids) async {
    for (final id in ids) {
      await cancelar(id);
    }
  }

  /// Aviso de prueba dentro de un minuto, para comprobar que suena.
  static Future<void> probarEnUnMinuto() => _programar(
        idPrueba,
        DateTime.now().add(const Duration(minutes: 1)),
        'Aviso de prueba',
        'Si ves esto, los avisos funcionan en tu celular.',
      );

  /// Reprograma todos los avisos futuros al abrir la app (por seguridad).
  static Future<void> reprogramarFuturos() async {
    await programarTodos(await baseDatos.avisosFuturos(DateTime.now()));
  }
}
