import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/plan.dart';

@immutable
sealed class PlanState {
  const PlanState();
}

class PlanInitial extends PlanState {
  const PlanInitial();
}

class PlanLoaded extends PlanState {
  final Plan plan;
  final DateTime? lastUpdate;
  final bool updating;
  final bool autoUpdateEnabled;

  const PlanLoaded({
    required this.plan,
    this.lastUpdate,
    this.updating = false,
    this.autoUpdateEnabled = false,
  });

  PlanLoaded copyWith({
    Plan? plan,
    List<Leg>? legs,
    DateTime? lastUpdate,
    bool? updating,
    bool? autoUpdateEnabled,
  }) {
    return PlanLoaded(
      plan: plan ?? this.plan,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      updating: updating ?? this.updating,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
    );
  }
}

class PlanError extends PlanState {
  final String message;
  final StackTrace? stackTrace;

  const PlanError(this.message, [this.stackTrace]);
}
