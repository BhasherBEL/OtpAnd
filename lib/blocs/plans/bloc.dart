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
        final pageInfo =
            PlansPageInfo.fromJson(result['pageInfo'] as Map<String, dynamic>);
        final searchDateTime = result['searchDateTime'] as String?;

        // For initial load, overall time range equals current search window
        final timeRange = _calculateOverallTimeRange(
          searchDateTime,
          pageInfo,
          null, // no existing start time
          null, // no existing end time
        );

        emit(
          PlansLoaded(
            result['plans'] as List<Plan>,
            pageInfo,
            event.variables,
            searchDateTime,
            overallSearchStartTime: timeRange['start'],
            overallSearchEndTime: timeRange['end'],
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

        final pageInfo =
            PlansPageInfo.fromJson(result['pageInfo'] as Map<String, dynamic>);
        final searchDateTime = result['searchDateTime'] as String?;

        // Calculate overall time range including existing range
        final timeRange = _calculateOverallTimeRange(
          searchDateTime,
          pageInfo,
          event.plansLoaded.overallSearchStartTime,
          event.plansLoaded.overallSearchEndTime,
        );

        emit(
          PlansLoaded(
            newPlans,
            pageInfo,
            variables,
            searchDateTime,
            overallSearchStartTime: timeRange['start'],
            overallSearchEndTime: timeRange['end'],
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

        final pageInfo =
            PlansPageInfo.fromJson(result['pageInfo'] as Map<String, dynamic>);
        final searchDateTime = result['searchDateTime'] as String?;

        // Calculate overall time range including existing range
        final timeRange = _calculateOverallTimeRange(
          searchDateTime,
          pageInfo,
          event.plansLoaded.overallSearchStartTime,
          event.plansLoaded.overallSearchEndTime,
        );

        emit(
          PlansLoaded(
            newPlans,
            pageInfo,
            variables,
            searchDateTime,
            overallSearchStartTime: timeRange['start'],
            overallSearchEndTime: timeRange['end'],
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

  Map<String, String?> _calculateOverallTimeRange(
    String? currentSearchDateTime,
    PlansPageInfo currentPageInfo,
    String? existingStartTime,
    String? existingEndTime,
  ) {
    if (currentSearchDateTime == null) {
      return {'start': existingStartTime, 'end': existingEndTime};
    }

    final searchTime = DateTime.tryParse(currentSearchDateTime);
    if (searchTime == null) {
      return {'start': existingStartTime, 'end': existingEndTime};
    }

    // Calculate current window end time
    String? currentEndTime;
    if (currentPageInfo.searchWindowUsed != null) {
      final duration = _parseDuration(currentPageInfo.searchWindowUsed!);
      if (duration != null) {
        final endTime = searchTime.add(duration);
        currentEndTime = endTime.toIso8601String();
      }
    }

    // Determine overall start time (earliest)
    String? overallStart = currentSearchDateTime;
    if (existingStartTime != null) {
      final existingStart = DateTime.tryParse(existingStartTime);
      if (existingStart != null && existingStart.isBefore(searchTime)) {
        overallStart = existingStartTime;
      }
    }

    // Determine overall end time (latest)
    String? overallEnd = currentEndTime;
    if (existingEndTime != null && currentEndTime != null) {
      final existingEnd = DateTime.tryParse(existingEndTime);
      final currentEnd = DateTime.tryParse(currentEndTime);
      if (existingEnd != null &&
          currentEnd != null &&
          existingEnd.isAfter(currentEnd)) {
        overallEnd = existingEndTime;
      }
    } else if (existingEndTime != null && currentEndTime == null) {
      overallEnd = existingEndTime;
    }

    return {'start': overallStart, 'end': overallEnd};
  }

  Duration? _parseDuration(String isoDuration) {
    if (!isoDuration.startsWith('PT')) return null;
    final timeString = isoDuration.substring(2);
    int hours = 0;
    int minutes = 0;

    final hoursMatch = RegExp(r'(\d+)H').firstMatch(timeString);
    if (hoursMatch != null) {
      hours = int.tryParse(hoursMatch.group(1)!) ?? 0;
    }

    final minutesMatch = RegExp(r'(\d+)M').firstMatch(timeString);
    if (minutesMatch != null) {
      minutes = int.tryParse(minutesMatch.group(1)!) ?? 0;
    }

    return Duration(hours: hours, minutes: minutes);
  }
}
