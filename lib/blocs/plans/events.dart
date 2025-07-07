import 'package:flutter/material.dart';
import 'package:otpand/blocs/plans/helpers.dart';
import 'package:otpand/blocs/plans/states.dart';
import 'package:otpand/objects/plan.dart';

@immutable
sealed class PlansEvent {
  const PlansEvent();
}

final class RefreshPlans extends PlansEvent {
  const RefreshPlans();
}

final class SelectPlan extends PlansEvent {
  final Plan plan;
  const SelectPlan(this.plan);
}

final class LoadPlans extends PlansEvent {
  final PlansQueryVariables variables;
  const LoadPlans(this.variables);
}

final class FindPreviousPlan extends PlansEvent {
  final PlansLoaded plansLoaded;

  const FindPreviousPlan(this.plansLoaded);
}

final class FindNextPlan extends PlansEvent {
  final PlansLoaded plansLoaded;

  const FindNextPlan(this.plansLoaded);
}
