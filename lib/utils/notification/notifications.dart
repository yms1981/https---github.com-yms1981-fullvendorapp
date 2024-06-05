import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:FullVendor/application/application_global_keys.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('launcher_icon');

/// Note: permissions aren't requested here just to demonstrate that can be
/// done later
DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
  requestAlertPermission: false,
  requestBadgePermission: false,
  requestSoundPermission: false,
  // defaultPresentAlert: false,
  // defaultPresentBadge: false,
  defaultPresentSound: false,
  // defaultPresentList: false,
  notificationCategories: [],
  onDidReceiveLocalNotification: (id, title, body, payload) async {
    // Handle notification received in foreground
    //   show snack bar if application is in foreground
    //   SnackBar snackBar = SnackBar(content: Text());
    FullVendor.instance.currentContext.showSnackBar(body ?? '');
  },
);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print('notification action tapped with input: ${notificationResponse.input}');
  }
}

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<bool> checkIsNotificationAllowed() async {
    var isIOS = Platform.isIOS;
    if (isIOS) {
      return (await flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                  ?.checkPermissions())
              ?.isEnabled ??
          false;
    } else {
      return (await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled()) ??
          false;
    }
  }

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidNotificationSetting =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    InitializationSettings initializationSettings = InitializationSettings(
        android: androidNotificationSetting, iOS: initializationSettingsDarwin);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// value to record timeout on sync for after 30 second
  static Timer? _autoCancelTimer;

  static Future<void> showProgressNotification({
    required ValueNotifier<double> progressNotifier,
    String title = "Database syncing",
    int? notificationId,
  }) async {
    notificationId ??= Random.secure().nextInt(1000);
    const int maxProgress = 100;
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(sound: null, presentAlert: false);

    Timer? timer;
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'progress_channel',
      'Progress Notifications',
      channelDescription: 'Notification channel for progress updates',
      importance: Importance.max,
      icon: 'ic_sync',
      priority: Priority.high,
      onlyAlertOnce: true,
      showProgress: true,
      // progress: progressNotifier.value.ceil().toInt(),
      maxProgress: maxProgress,
      indeterminate: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    // Listening to the progressNotifier changes and updating the notification
    progressNotifier.addListener(() async {
      // Decimal progress = Decimal.fromInt();
      double value = progressNotifier.value;
      if (value == 0) return;
      String progress = value.toStringWithoutRounding(2);
      _autoCancelTimer?.cancel();
      timer?.cancel();
      _autoCancelTimer = Timer(const Duration(minutes: 3), () async {
        progressNotifier.value = 0;
        await _notificationsPlugin.cancel(notificationId!);
      });

      String progressText = 'Progress: $progress%';
      if (progressText.contains("100")) {
        progressText = "Download completed.";
        _notificationsPlugin.cancel(notificationId!);
      } else {
        var delayInMs = Platform.isIOS ? 500 : 0;
        timer = Timer(Duration(milliseconds: delayInMs), () async {
          await _notificationsPlugin.show(
            notificationId!,
            title,
            progressText,
            platformChannelSpecifics,
            payload: 'progress_payload',
          );
        });
      }
    });
  }

  // function to ask notification permission
  static Future<bool?> askNotificationPermission() async {
    var isIOS = Platform.isIOS;
    var notificationPlugIn = flutterLocalNotificationsPlugin;
    bool? isAllowed;
    if (isIOS) {
      isAllowed = await notificationPlugIn
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else {
      isAllowed = await notificationPlugIn
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    return isAllowed;
  }
}
