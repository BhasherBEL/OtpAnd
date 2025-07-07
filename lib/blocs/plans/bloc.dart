import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otpand/blocs/plans/events.dart';
import 'package:otpand/blocs/plans/helpers.dart';
import 'package:otpand/blocs/plans/repository.dart';
import 'package:otpand/blocs/plans/states.dart';
import 'package:otpand/objects/plan.dart';

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final PlansRepository repository;

  PlansBloc(this.repository) : super(const PlansInitial()) {
    on<LoadPlans>((event, emit) async {
      emit(const PlansLoading());
      try {
        final result = await repository.fetchPlans(event.variables);
        emit(
          PlansLoaded(
            result['plans'] as List<Plan>,
            PlansPageInfo.fromJson(result['pageInfo'] as Map<String, dynamic>),
            event.variables,
          ),
        );
      } on SocketException catch (e, s) {
        emit(PlansError(e.toString(), s));
      } on TimeoutException catch (e, s) {
        emit(PlansError(e.toString(), s));
      } on Exception catch (e) {
        emit(PlansError(e.toString(), null));
      }
    });

    on<FindPreviousPlan>((event, emit) async {
      emit(PlansLoadingPrevious(event.plansLoaded));
      try {
        final variables = event.plansLoaded.variables
            .copyWith(before: event.plansLoaded.pageInfo.startCursor);
        final result = await repository.fetchPlans(variables);
        final newPlans = event.plansLoaded.plans
          ..addAll((result['plans'] as List<Plan>)
              .where((p) => !event.plansLoaded.plans.contains(p)));
        emit(
          PlansLoaded(
            newPlans,
            PlansPageInfo.fromJson(result['pageInfo'] as Map<String, dynamic>),
            variables,
          ),
        );
      } on SocketException catch (e, s) {
        emit(PlansExtendError(event.plansLoaded, e.toString(), s));
      } on TimeoutException catch (e, s) {
        emit(PlansExtendError(event.plansLoaded, e.toString(), s));
      } on Exception catch (e) {
        emit(PlansExtendError(event.plansLoaded, e.toString(), null));
      }
    });

    on<FindNextPlan>((event, emit) async {
      emit(PlansLoadingNext(event.plansLoaded));
      try {
        final variables = event.plansLoaded.variables
            .copyWith(before: event.plansLoaded.pageInfo.endCursor);
        final result = await repository.fetchPlans(variables);
        final newPlans = event.plansLoaded.plans
          ..addAll((result['plans'] as List<Plan>)
              .where((p) => !event.plansLoaded.plans.contains(p)));
        emit(
          PlansLoaded(
            newPlans,
            PlansPageInfo.fromJson(result['pageInfo'] as Map<String, dynamic>),
            variables,
          ),
        );
      } on SocketException catch (e, s) {
        emit(PlansError(e.toString(), s));
      } on TimeoutException catch (e, s) {
        emit(PlansError(e.toString(), s));
      } on Exception catch (e) {
        emit(PlansError(e.toString(), null));
      }
    });
  }
}
