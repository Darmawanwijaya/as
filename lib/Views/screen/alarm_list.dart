import 'package:fcm/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fcm/model/alarm_model.dart';
import 'package:fcm/Views/screen/setting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:fcm/bloc/cubit/alarm_cubit.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({Key? key}) : super(key: key);

  @override
  _AlarmListScreenState createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  final AlarmCubit alarmCubit = AlarmCubit();

  late TextEditingController titleController;
  late TextEditingController timeController;
  late TextEditingController descController;

  Future<void> initNotification(BuildContext context) async {
    AndroidInitializationSettings androidInitializationSettings = 
    const AndroidInitializationSettings('@mipmap/ic_launcher');

    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: ((details) {
        if(details.payload!.isNotEmpty){
          if(details.payload == 'item x'){
            showAlarmDetailsDialog;
          }
        }
      })

    );
  }

  @override
  void initState() {
    super.initState();
    initNotification(context);
    titleController = TextEditingController();
    timeController = TextEditingController();
    descController = TextEditingController();

    // Load alarms when the screen is initialized
    _loadAlarms();
  }

  @override
  void dispose() {
    titleController.dispose();
    timeController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    // Load alarms when the screen is initialized
    alarmCubit.loadAlarms();
  }

  Widget _buildTimePickerField() {
    return TextFormField(
      onTap: _selectTime,
      readOnly: true,
      controller: timeController,
      decoration: const InputDecoration(
        labelText: 'Time',
        suffixIcon: Icon(Icons.access_time),
      ),
    );
  }

  Future<void> _selectTime() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      timeController.text = DateFormat('HH:mm').format(
        DateTime(2023, 1, 1, selectedTime.hour, selectedTime.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm'),
        backgroundColor: const Color.fromARGB(47, 4, 4, 4),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => alarmCubit,
        child: BlocBuilder<AlarmCubit, AlarmState>(
          builder: (context, state) {
            if (state is AlarmsLoadedState) {
              if (state.alarms.isEmpty) {
                return const Center(
                  child: Text('No alarms available'),
                );
              }

              return _buildAlarmList(state.alarms);
            } else if (state is AlarmErrorState) {
              return Center(
                child: Text('Error: ${state.error}'),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlarmList(List<AlarmList> alarms) {
    return ListView.separated(
      itemCount: alarms.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        color: Colors.grey,
      ),
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return ListTile(
          title: Text(alarm.title),
          subtitle: Text(alarm.description.time),
          onTap: () => showAlarmDetailsDialog(alarm),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteAlarm(alarm),
          ),
        );
      },
    );
  }

  Future<void> _showAddAlarmBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.43,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Alarm',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),
                _buildTimePickerField(),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _setAlarm,
                  child: const Text('Set Alarm'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setAlarm() async {
    alarmCubit.addAlarm(
      AlarmList(
        title: titleController.text,
        description: Description(
          alarmTitle: titleController.text,
          time: timeController.text,
          desc: descController.text,
        ),
      ),
    );

    // Clear text controllers
    titleController.clear();
    timeController.clear();
    descController.clear();

    Navigator.pop(context);
  }

  Future<void> showAlarmDetailsDialog(AlarmList alarm) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(alarm.title),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Time: ${alarm.description.time}'),
              Text('Description: ${alarm.description.desc}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAlarm(AlarmList alarm) async {
    alarmCubit.deleteAlarm(alarm);
  }
}
