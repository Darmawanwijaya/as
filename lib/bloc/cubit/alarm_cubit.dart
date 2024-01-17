import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:fcm/model/alarm_model.dart';
import 'package:fcm/ViewModel/alarm_viewmodel.dart';

part 'alarm_state.dart';
part 'alarm_event.dart';

class AlarmCubit extends Cubit<AlarmState> {
  final AlarmViewModel viewModel = AlarmViewModel();

  AlarmCubit() : super(AlarmInitial());

  void loadAlarms() async {
    try {
      final alarms = await viewModel.getAlarmsFromLocalStorage();
      emit(AlarmsLoadedState(alarms));
    } catch (e) {
      emit(AlarmErrorState('Failed to load alarms: $e'));
    }
  }

  void addAlarm(AlarmList alarm) async {
    try {
      await viewModel.createAlarm(
          alarm.title, alarm.description.time, alarm.description.desc);
      await Future.delayed(const Duration(seconds: 0));
      loadAlarms();
    } catch (e) {
      emit(AlarmErrorState('Failed to add alarm: $e'));
    }
  }

  void deleteAlarm(AlarmList alarm) async {
    try {
      await viewModel.deleteAlarm(alarm);
      loadAlarms();
    } catch (e) {
      emit(AlarmErrorState('Failed to delete alarm: $e'));
    }
  }
}
