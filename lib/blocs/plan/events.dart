import 'package:flutter/material.dart';
import 'package:otpand/objects/plan.dart';

@immutable
sealed class PlanEvent {
  const PlanEvent();
}

final class StorePlan extends PlanEvent {
  final Plan plan;
  const StorePlan(this.plan);
}

final class DeletePlan extends PlanEvent {
  final Plan plan;
  const DeletePlan(this.plan);
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

final class LoadPlanLegs extends PlanEvent {
  final Plan plan;
  const LoadPlanLegs(this.plan);
}
