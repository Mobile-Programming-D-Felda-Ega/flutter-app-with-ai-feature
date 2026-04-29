import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/study_group.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'study_group_channel',
    'Study Group Notifications',
    description: 'Notifications for invites and meetup reminders',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tzdata.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));

    if (!kIsWeb) {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _plugin.initialize(settings: initializationSettings);

      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.createNotificationChannel(_channel);
      await androidImplementation?.requestNotificationsPermission();

      final darwinImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await darwinImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      // For web, initialize with minimal settings
      const initializationSettings = InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );
      await _plugin.initialize(settings: initializationSettings);
    }

    _initialized = true;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'study_group_channel',
        'Study Group Notifications',
        channelDescription: 'Notifications for invites and meetup reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showInviteNotification(StudyGroup group) async {
    await _showImmediateNotification(
      id: group.id.hashCode ^ 1000,
      title: 'Invite Study Group',
      body: 'Kamu diundang ke ${group.subjectName} pada ${group.location}',
    );
  }

  Future<void> showTestNotification() async {
    await _showImmediateNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: 'Test Notification',
      body: 'Kalau ini muncul, izin notifikasi sudah beres.',
    );
  }

  Future<void> scheduleReminder(StudyGroup group) async {
    if (kIsWeb) {
      final reminderTime = group.scheduledAt.subtract(
        const Duration(minutes: 1),
      );
      final timeUntilReminder = reminderTime.difference(DateTime.now());

      if (timeUntilReminder.isNegative) {
        // Kalau waktu sudah passed, show immediately
        _showWebNotification(
          'Reminder Meetup',
          'Meetup ${group.subjectName} akan segera dimulai di ${group.location}',
        );
      } else {
        // Schedule untuk nanti
        Future.delayed(timeUntilReminder, () {
          _showWebNotification(
            'Reminder Meetup',
            'Meetup ${group.subjectName} akan segera dimulai di ${group.location}',
          );
        });
      }
    } else {
      final reminderTime = group.scheduledAt.subtract(
        const Duration(minutes: 1),
      );
      final scheduledTime = reminderTime.isAfter(DateTime.now())
          ? reminderTime
          : DateTime.now().add(const Duration(seconds: 10));

      await _plugin.zonedSchedule(
        id: group.id.hashCode ^ 2000,
        title: 'Reminder Meetup',
        body:
            'Meetup ${group.subjectName} akan segera dimulai di ${group.location}',
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      _showWebNotification(title, body);
      return;
    }

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  void _showWebNotification(String title, String body) {
    if (kIsWeb) {
      try {
        // For web, we can use flutter_local_notifications which has web support
        final notificationId = title.hashCode & 0x7fffffff;
        _plugin.show(id: notificationId, title: title, body: body);
      } catch (e) {
        // Silent fail if notification API not available
        print('Web notification failed: $e');
      }
    }
  }
}
