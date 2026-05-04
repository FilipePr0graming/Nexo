import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/reminder_model.dart';

class LocalReminderNotifications {
  LocalReminderNotifications();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    if (_initialized) {
      return;
    }

    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('America/Sao_Paulo'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> schedule(ReminderModel reminder) async {
    await initialize();
    if (!_initialized || reminder.status != ReminderStatus.open) {
      return;
    }

    final due = reminder.dueDate.toLocal();
    if (!due.isAfter(DateTime.now())) {
      return;
    }

    await _plugin.zonedSchedule(
      id: notificationId(reminder.id),
      title: reminder.title,
      body: reminder.description ?? 'Lembrete do Nexo',
      scheduledDate: timezone.TZDateTime.from(due, timezone.local),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'nexo_reminders',
          'Lembretes Nexo',
          channelDescription: 'Lembretes de contas, cobrancas, notas e metas.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: reminder.id,
    );
  }

  Future<void> cancel(String reminderId) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(id: notificationId(reminderId));
  }

  int notificationId(String value) {
    return value.hashCode & 0x7fffffff;
  }
}
