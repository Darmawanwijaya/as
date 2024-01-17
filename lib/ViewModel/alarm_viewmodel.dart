import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fcm/model/alarm_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AlarmViewModel {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AlarmViewModel() {
    // Initialize time zone support
    tz.initializeTimeZones();
  }
  
  Future<void> showAlarmDetailsDialog(AlarmList alarm) async {
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(alarm.title),
        Text('Time: ${alarm.description.time}'),
        Text('Description: ${alarm.description.desc}'),
      ],
    );
      
  }
  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel_id',
      'Alarm Notification',
      channelDescription: 'test',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> scheduleAlarmNotification(
      String title, String body, DateTime alarmTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'Default Channel',
      'Channel for alarm notifications',
      importance: Importance.max,
      icon: "@mipmap/ic_launcher",
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        final now = DateTime.now();
        var alarmTimes = DateTime(now.year, now.month, now.day, alarmTime.hour, alarmTime.minute);
        if (alarmTime.isBefore(now)) {
          alarmTime = alarmTimes.add(const Duration(days: 1));
        }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(alarmTime, tz.local),
      platformChannelSpecifics,
      payload: 'item x',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> createAlarm(String title, String time, String desc) async {
    try {
      final alarmList = AlarmList(
        title: title,
        description: Description(alarmTitle: title, time: time, desc: desc),
      );

      // Save the alarm to local storage
      saveAlarmToLocalStorage(alarmList);

      // Schedule the alarm notification
      final alarmTime = parseAlarmTime(time);
      await scheduleAlarmNotification(
        'New Alarm',
        'Title: $title, Time: $time, Description: $desc',
        alarmTime,
      );

      // Show local notification
      await showLocalNotification(
          'New Alarm', 'Title: $title, Time: $time, Description: $desc');

      print('Alarm set successfully.');
    } catch (e) {
      print('Error creating alarm: $e');
    }
  }

  DateTime parseAlarmTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hours, minutes);
    } else {
      return DateTime.now();
    }
  }

  Future<void> sendFCMNotification(String title, String body) async {
    try {
      const String serverKey =
          'AAAA5mVc8wE:APA91bHr6LKHzibBIi7vx-7qVGYPlENX7q8V7wM7U8A_flTdLD5oR9trgBYJQlaemz5dMNYaSWm_fndEieS3T3kqUvGx_F2xWfZg-rF7Gv0dbNAQfiiQm8O5gC5VlzAoDoeJkSkTA3MN';
      const String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

      final Map<String, dynamic> notificationData = {
        'notification': {
          'title': title,
          'body': body,
        },
        'to':
            "dFSPHKo_TFqMj91IB7WQVF:APA91bEWq1pzytfQu4OrQCJ3HOGO6Gzc4Y-25gIACaCLAkoZVRXHHLuOLaHDpF-Vc3A9ZWGG8qBD0izjg3SNmSVFq5baSQrxWO2s1_kZU0RMkyMv5xWA_jftslTzM3nl3hpr75dus2QS",
      };

      final http.Response response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(notificationData),
      );

      if (response.statusCode != 200) {
        print(
            'FCM notification failed with status code: ${response.statusCode}');
        // Handle the failure as needed
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
      // Handle the error as needed
    }
  }

  Future<void> saveAlarmToLocalStorage(AlarmList alarmList) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedAlarms = prefs.getStringList('alarms') ?? [];
    savedAlarms.add(jsonEncode(alarmList.toJson()));
    prefs.setStringList('alarms', savedAlarms);
  }

  Future<List<AlarmList>> getAlarmsFromLocalStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedAlarms = prefs.getStringList('alarms') ?? [];
    return savedAlarms
        .map((jsonString) => AlarmList.fromJson(jsonDecode(jsonString)))
        .toList();
  }

  Future<void> deleteAlarm(AlarmList alarm) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final savedAlarms = prefs.getStringList('alarms') ?? [];

      savedAlarms.removeWhere(
        (jsonString) {
          final storedAlarm = AlarmList.fromJson(jsonDecode(jsonString));
          return areAlarmsEqual(storedAlarm, alarm);
        },
      );

      prefs.setStringList('alarms', savedAlarms);

      print('Alarm deleted successfully.');
    } catch (e) {
      print('Error deleting alarm: $e');
    }
  }

  bool areAlarmsEqual(AlarmList alarm1, AlarmList alarm2) {
    return alarm1.title == alarm2.title &&
        alarm1.description.time == alarm2.description.time &&
        alarm1.description.desc == alarm2.description.desc;
  }
}