import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService();

  /// Initialize Notifications (FCM + Local)
  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click if needed
      },
    );

    // 3. Setup FCM handlers
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground message
      if (message.notification != null) {
        _showForegroundNotification(message.notification!);
      }
    });

    // 4. Schedule Re-engagement if user is logged in
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await scheduleReengagementNotifications();
      }
    } catch (_) {}
  }

  /// Request permissions for iOS and Android 13+
  Future<void> requestPermissions() async {
    // FCM Permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications iOS permission request
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Local notifications Android 13+ permission request
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Show a foreground push notification as a local notification
  Future<void> _showForegroundNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'Alerts',
      channelDescription: 'FCM push notification delivery channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }

  /// Schedule Daily Reminders
  Future<void> scheduleDailyReminders() async {
    // Cancel existing scheduled notifications to avoid duplicates
    await _localNotifications.cancelAll();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders_channel',
      'Daily Reminders',
      channelDescription: 'Channel for daily recovery reminder alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // 1. Mood Reminder: 8:00 PM (20:00)
    await _localNotifications.zonedSchedule(
      101,
      'How are you feeling today?',
      'Take a moment to check in with your emotions.',
      _nextInstanceOfTime(20, 0),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 2. Task Reminder: 9:00 AM (09:00)
    await _localNotifications.zonedSchedule(
      102,
      'Ready for your healing tasks?',
      'Completing small goals builds your streak and helps you recover.',
      _nextInstanceOfTime(9, 0),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Reschedule re-engagement notifications as well
    await scheduleReengagementNotifications();
  }

  /// Schedule Re-engagement Alerts (24h, 72h, 7d)
  Future<void> scheduleReengagementNotifications() async {
    try {
      await _localNotifications.cancel(201);
      await _localNotifications.cancel(202);
      await _localNotifications.cancel(203);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reengagement_channel',
        'Re-engagement Alerts',
        channelDescription: 'Reminders to log in and continue recovery when inactive',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

      // 24h reminder
      await _localNotifications.zonedSchedule(
        201,
        'Your daily check-in is waiting',
        'Take a moment to record your mood and maintain your streak.',
        now.add(const Duration(hours: 24)),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // 72h reminder
      await _localNotifications.zonedSchedule(
        202,
        'Small steps build progress',
        'It has been 3 days. Reconnect with your healing path.',
        now.add(const Duration(hours: 72)),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // 7d reminder
      await _localNotifications.zonedSchedule(
        203,
        'Your healing journey matters',
        'A week of progress awaits. Let\'s review your insights.',
        now.add(const Duration(days: 7)),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// Helper to calculate the next occurrence of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
