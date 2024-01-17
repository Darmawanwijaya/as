part of 'alarm_cubit.dart';


@immutable
class AlarmState {}

class AlarmInitial extends AlarmState {}

class AlarmsLoadedState extends AlarmState {
  final List<AlarmList> alarms;

  AlarmsLoadedState(this.alarms);
}

class AlarmErrorState extends AlarmState {
  final String error;

  AlarmErrorState(this.error);
}
