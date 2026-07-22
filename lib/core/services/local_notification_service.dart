import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local scheduled notifications for medication reminders — deliberately
/// not an AI feature (architecture doc §11): a
/// `medication_reminders/{uid}/items/{id}` document drives recurring
/// on-device notifications, no server/LLM call involved.
///
/// Notification ids are derived deterministically from
/// `(reminderId, dayOfWeek, time)` so a reminder can always be
/// cancelled-and-rescheduled by recomputing the same ids, without needing
/// to persist which ids were used.
///
/// flutter_local_notifications has no Windows implementation (only
/// Android/iOS/macOS/Linux) — every public method below is a no-op on an
/// unsupported platform rather than throwing, since this app also builds
/// for Windows desktop (see windows/ in the repo).
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'medication_reminders';
  static const _channelName = 'Medication Reminders';

  /// False on Windows/Linux/web — callers use this to skip the permission
  /// prompt rather than block reminder creation on unsupported platforms.
  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  bool get _isSupportedPlatform => isSupportedPlatform;

  Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) return;

    tzdata.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      // Falls back to UTC (the `timezone` package default) if the platform
      // timezone lookup fails — reminders still fire, just against UTC wall
      // clock until this resolves on a later app start.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Reminders to take your medication on schedule',
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!_isSupportedPlatform) return false;
    await initialize();
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  /// One stable int id per (reminder, day, time) combination — used both to
  /// schedule and, later, to cancel exactly these notifications without
  /// tracking generated ids anywhere.
  int _notificationId(String reminderId, int dayOfWeek, String time) {
    return Object.hash(reminderId, dayOfWeek, time) & 0x7fffffff;
  }

  /// Schedules one recurring weekly notification per (day, time) pair.
  /// `daysOfWeek` uses `DateTime.monday`(1)..`DateTime.sunday`(7);
  /// `times` are `"HH:mm"` 24-hour strings.
  Future<void> scheduleReminder({
    required String reminderId,
    required String medicineName,
    required List<int> daysOfWeek,
    required List<String> times,
  }) async {
    if (!_isSupportedPlatform) return;
    await initialize();
    for (final day in daysOfWeek) {
      for (final time in times) {
        final parts = time.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

        await _plugin.zonedSchedule(
          _notificationId(reminderId, day, time),
          'Medication reminder',
          'Time to take $medicineName',
          _nextInstanceOfWeekdayTime(day, hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          // Inexact is deliberate: medication reminders don't need
          // millisecond precision, and this avoids requiring the Android 12+
          // "Alarms & reminders" special-access permission that
          // exactAllowWhileIdle would need.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> cancelReminder({
    required String reminderId,
    required List<int> daysOfWeek,
    required List<String> times,
  }) async {
    if (!_isSupportedPlatform) return;
    for (final day in daysOfWeek) {
      for (final time in times) {
        await _plugin.cancel(_notificationId(reminderId, day, time));
      }
    }
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = tz.TZDateTime.now(tz.local);
    scheduled = tz.TZDateTime(
      tz.local,
      scheduled.year,
      scheduled.month,
      scheduled.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
