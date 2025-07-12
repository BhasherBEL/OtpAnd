import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otpand/blocs/plan/events.dart';
import 'package:otpand/blocs/plan/repository.dart';
import 'package:otpand/blocs/plan/states.dart';

class PlanBloc extends Bloc<PlanEvent, PlanState> {
  final PlanRepository repository;
  Timer? _autoUpdateTimer;

  PlanBloc(this.repository) : super(const PlanInitial()) {
    on<LoadPlan>((event, emit) {
      final hasRealTime = event.plan.legs.any((leg) => leg.realTime == true);

      emit(PlanLoaded(
        plan: event.plan,
        lastUpdate: DateTime.now(),
        autoUpdateEnabled: hasRealTime,
      ));

      if (hasRealTime) {
        _startAutoUpdate();
      }
    });

    on<UpdateLegs>((event, emit) async {
      if (state is PlanLoaded) {
        final currentState = state as PlanLoaded;
        emit(currentState.copyWith(updating: true));

        try {
          final updatedLegs =
              await repository.updateLegs(currentState.plan.legs);
          emit(currentState.copyWith(
            plan: currentState.plan.copyWith(
              legs: updatedLegs,
            ),
            legs: updatedLegs,
            lastUpdate: DateTime.now(),
            updating: false,
          ));
        } on Exception catch (e, st) {
          emit(PlanError(e.toString(), st));
        }
      }
    });

    on<ToggleAutoUpdate>((event, emit) {
      if (state is PlanLoaded) {
        final currentState = state as PlanLoaded;
        final newAutoUpdateEnabled = !currentState.autoUpdateEnabled;

        emit(currentState.copyWith(autoUpdateEnabled: newAutoUpdateEnabled));

        if (newAutoUpdateEnabled) {
          _startAutoUpdate();
        } else {
          _stopAutoUpdate();
        }
      }
    });
  }

  void _startAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      add(const UpdateLegs());
    });
  }

  void _stopAutoUpdate() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = null;
  }

  @override
  Future<void> close() {
    _autoUpdateTimer?.cancel();
    return super.close();
  }
}
