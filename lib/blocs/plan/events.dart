import 'package:flutter/material.dart';
import 'package:otpand/objects/plan.dart';

@immutable
sealed class PlanEvent {
  const PlanEvent();
}

final class LoadPlan extends PlanEvent {
  final Plan plan;
  const LoadPlan(this.plan);
}

final class UpdateLegs extends PlanEvent {
  const UpdateLegs();
}

final class ToggleAutoUpdate extends PlanEvent {
  const ToggleAutoUpdate();
}
