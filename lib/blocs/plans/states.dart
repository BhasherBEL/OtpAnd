import 'package:flutter/material.dart';
import 'package:otpand/blocs/plans/helpers.dart';
import 'package:otpand/objects/plan.dart';

@immutable
sealed class PlansState {
  const PlansState();
}

class PlansInitial extends PlansState {
  const PlansInitial();
}

class PlansLoading extends PlansState {
  const PlansLoading();
}

class PlansLoaded extends PlansState {
  final List<Plan> plans;
  final PlansPageInfo pageInfo;
  final PlansQueryVariables variables;
  final String? searchDateTime;
  final String? overallSearchStartTime;
  final String? overallSearchEndTime;

  const PlansLoaded(
    this.plans, 
    this.pageInfo, 
    this.variables, 
    this.searchDateTime, {
    this.overallSearchStartTime,
    this.overallSearchEndTime,
  });
}

class PlansError extends PlansState {
  final String message;
  final StackTrace? stack;

  const PlansError(this.message, this.stack);
}

class PlansExtendError extends PlansState {
  final PlansLoaded plansLoaded;
  final String message;
  final StackTrace? stack;

  const PlansExtendError(
    this.plansLoaded,
    this.message,
    this.stack,
  );
}

class PlansLoadingPrevious extends PlansState {
  final PlansLoaded plansLoaded;

  const PlansLoadingPrevious(this.plansLoaded);
}

class PlansLoadingNext extends PlansState {
  final PlansLoaded plansLoaded;

  const PlansLoadingNext(this.plansLoaded);
}
