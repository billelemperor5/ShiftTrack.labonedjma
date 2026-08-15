import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/attendance_record.dart';
import '../models/user_profile.dart';
import 'hive_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _daysToSchedule = 45;
  static const String _channelId = 'attendance_reminders';
  static const String _channelName = 'Rappels de pointage';
  static const String _channelDescription =
      'Rappels automatiques pour pointer arrivée et départ.';

  static Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Algiers'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: android);

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (!_initialized) await init();
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  static Future<void> configureFromSavedProfile() async {
    if (kIsWeb) return;
    if (HiveService.getUserBox().isEmpty) return;
    final profile = HiveService.getUserBox().getAt(0);
    if (profile == null) return;
    await configure(profile);
  }

  static Future<void> configure(UserProfile profile) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    await cancelAttendanceReminders();

    if (!profile.notificationsEnabled) return;

    final allowedDays = profile.notificationWorkDays
        .where((day) => day != DateTime.friday)
        .toSet();
    if (allowedDays.isEmpty) return;

    final now = DateTime.now();
    for (var offset = 0; offset < _daysToSchedule; offset++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offset));
      if (!allowedDays.contains(date.weekday)) continue;

      final record = _recordForDate(date);
      if (record?.status == AttendanceStatus.absent) continue;

      if (record?.checkIn == null) {
        await _scheduleReminder(
          id: _notificationId(date, 1),
          dateTime: _dateWithTime(date, profile.defaultCheckIn),
          title: 'Rappel de pointage',
          body: 'N’oubliez pas de pointer votre arrivée.',
        );
      }

      if (record?.checkOut == null) {
        await _scheduleReminder(
          id: _notificationId(date, 2),
          dateTime: _dateWithTime(date, profile.defaultCheckOut),
          title: 'Rappel de départ',
          body: 'N’oubliez pas de pointer votre départ.',
        );
      }
    }
  }

  static Future<void> cancelAttendanceReminders() async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    await _plugin.cancelAll();
  }

  static Future<void> refreshAfterAttendanceChange(DateTime date) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    await _plugin.cancel(id: _notificationId(date, 1));
    await _plugin.cancel(id: _notificationId(date, 2));
    await configureFromSavedProfile();
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    await _plugin.show(
      id: 700001,
      title: 'Notifications activées',
      body: 'Les rappels de pointage sont prêts.',
      notificationDetails: _notificationDetails(),
    );
  }

  static Future<void> _scheduleReminder({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    if (!dateTime.isAfter(now)) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(dateTime, tz.local),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'attendance_reminder',
    );
  }

  static NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    return const NotificationDetails(android: android);
  }

  static AttendanceRecord? _recordForDate(DateTime date) {
    final target = DateFormat('yyyy-MM-dd').format(date);
    for (final record in HiveService.getAttendanceBox().values) {
      if (DateFormat('yyyy-MM-dd').format(record.date) == target) {
        return record;
      }
    }
    return null;
  }

  static DateTime _dateWithTime(DateTime date, String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static int _notificationId(DateTime date, int type) {
    return (date.year * 10000 + date.month * 100 + date.day) * 10 + type;
  }
}
