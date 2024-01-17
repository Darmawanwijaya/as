import 'dart:convert';
import 'package:http/http.dart' as http;

class AlarmList {
  String title;
  Description description;

  AlarmList({
    required this.title,
    required this.description,
  });

  static AlarmList defaultInstance() {
    return AlarmList(
      title: 'Default Title',
      description: Description.defaultInstance(),
    );
  }

  factory AlarmList.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('title') && json.containsKey('description')) {
      return AlarmList(
        title: json['title'],
        description: Description.fromJson(json['description']),
      );
    } else {
      throw const FormatException('Failed to load AlarmList from JSON.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description.toJson(),
    };
  }

  Future<AlarmList> createAlarm(String title) async {
    final response = await http.post(
      Uri.parse('https://jsonplaceholder.typicode.com/alarms'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': title,
      }),
    );

    if (response.statusCode == 201) {
      try {
        return AlarmList.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } catch (e) {
        throw Exception('Failed to parse response JSON.');
      }
    } else {
      throw Exception(
        'Failed to create alarm. Status code: ${response.statusCode}',
      );
    }
  }
}

class Description {
  String alarmTitle;
  String time;
  String desc;

  Description({
    required this.alarmTitle,
    required this.time,
    required this.desc,
  });

  static Description defaultInstance() {
    return Description(
      alarmTitle: 'alarmTitle',
      time: '00:00',
      desc: 'desc',
    );
  }

  factory Description.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('alarmTitle') &&
        json.containsKey('time') &&
        json.containsKey('desc')) {
      return Description(
        alarmTitle: json['alarmTitle'],
        time: json['time'],
        desc: json['desc'],
      );
    } else {
      throw const FormatException('Failed to load Description from JSON.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'alarmTitle': alarmTitle,
      'time': time,
      'desc': desc,
    };
  }
}
