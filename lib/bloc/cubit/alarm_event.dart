part of 'alarm_cubit.dart';

abstract class AlarmEvent {}

class LoadAlarmsEvent extends AlarmEvent {}

class AddAlarmEvent extends AlarmEvent {
  final AlarmList alarm;

  AddAlarmEvent(this.alarm);
}

class DeleteAlarmEvent extends AlarmEvent {
  final AlarmList alarm;

  DeleteAlarmEvent(this.alarm);
}