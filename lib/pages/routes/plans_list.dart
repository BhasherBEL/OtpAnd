import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otpand/blocs/plans/bloc.dart';
import 'package:otpand/blocs/plans/events.dart';
import 'package:otpand/blocs/plans/states.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/pages/plan.dart';
import 'package:otpand/widgets/smallroute.dart';
import 'package:intl/intl.dart';

class PlansListWidget extends StatelessWidget {
  const PlansListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<PlansBloc>().state;

    if (state is PlansLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (state is PlansError) {
      return Center(
        child: Text(
          state.message,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (state is PlansInitial) {
      return Center(
        child: Text('Please select a start and end location to find routes.'),
      );
    }

    PlansLoaded loadedState;

    if (state is PlansLoaded) {
      loadedState = state;
    } else if (state is PlansExtendError) {
      loadedState = state.plansLoaded;
    } else if (state is PlansLoadingNext) {
      loadedState = state.plansLoaded;
    } else if (state is PlansLoadingPrevious) {
      loadedState = state.plansLoaded;
    } else {
      throw 'Unmanaged state: $state';
    }

    final searchStartTime = _getSearchStartTime(loadedState);
    final searchEndTime = _getSearchEndTime(loadedState);

    return Padding(
      padding: const EdgeInsets.only(bottom: 150),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state is PlansLoadingPrevious)
            CircularProgressIndicator()
          else if (loadedState.pageInfo.hasPreviousPage) ...[
            TextButton(
              onPressed: () => _onShowEarlierTrips(context, loadedState),
              child: Text('Show earlier trips'),
            ),
            if (searchStartTime != null) _buildTimeIndicator(searchStartTime),
          ],
          if (loadedState.plans.isEmpty)
            Text('No plans found.')
          else
            ..._buildPlansList(loadedState.plans, context),
          if (state is PlansLoadingNext)
            CircularProgressIndicator()
          else if (loadedState.pageInfo.hasNextPage) ...[
            if (searchEndTime != null)
              _buildTimeIndicator(searchEndTime, isEnd: false),
            TextButton(
              onPressed: () => _onShowNextTrips(context, loadedState),
              child: Text('Show next trips'),
            ),
          ],
        ],
      ),
    );
  }

  String? _getSearchStartTime(PlansLoaded state) {
    if (state.overallSearchStartTime == null) return null;

    final searchTime = DateTime.tryParse(state.overallSearchStartTime!);
    if (searchTime == null) return null;

    final localTime = searchTime.toLocal();
    return DateFormat('HH:mm').format(localTime);
  }

  String? _getSearchEndTime(PlansLoaded state) {
    if (state.overallSearchEndTime == null) return null;

    final searchTime = DateTime.tryParse(state.overallSearchEndTime!);
    if (searchTime == null) return null;

    final localTime = searchTime.toLocal();
    return DateFormat('HH:mm').format(localTime);
  }

  Widget _buildTimeIndicator(String time, {bool isEnd = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          if (!isEnd) ...[
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[300],
            ),
          ),
          if (isEnd) ...[
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getTransferCount(Plan plan) {
    final transitLegs = plan.legs.where((leg) => leg.transitLeg).toList();
    if (transitLegs.length <= 1) return 0;
    int transfers = 0;
    for (int i = 1; i < transitLegs.length; i++) {
      final prevRoute = transitLegs[i - 1].route?.shortName ?? '';
      final currentRoute = transitLegs[i].route?.shortName ?? '';
      if (prevRoute != currentRoute) {
        transfers++;
      }
    }
    return transfers;
  }

  int _getWalkingDistance(Plan plan) {
    return plan.legs
        .where((leg) =>
            leg.mode == 'WALK' || leg.mode == 'BICYCLE' || leg.mode == 'CAR')
        .fold<int>(0, (sum, leg) => sum + leg.distance.round());
  }

  Iterable<Widget> _buildPlansList(List<Plan> plans, BuildContext context) {
    final shortestPlan = plans
        .reduce((p1, p2) => p1.getDuration() < p2.getDuration() ? p1 : p2)
        .getDuration();
    final double lowestEmissions = plans
        .reduce((p1, p2) => p1.getEmissions() < p2.getEmissions() ? p1 : p2)
        .getEmissions();
    final int lowestWalk = plans
        .map(_getWalkingDistance)
        .fold<int>(9999999, (min, w) => w < min ? w : min);

    plans.sort((a, b) {
      if (a.end == b.end) return 0;

      final aTime = DateTime.tryParse(a.end) ?? DateTime.now();
      final bTime = DateTime.tryParse(b.end) ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    return plans.map((plan) {
      return SmallRoute(
        plan: plan,
        shortestPlan: shortestPlan,
        lowestEmissions: lowestEmissions,
        lowestWalk: lowestWalk,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => PlanPage(plan: plan)),
          );
        },
      );
    });
  }

  void _onShowEarlierTrips(BuildContext context, PlansLoaded state) {
    if (!state.pageInfo.hasPreviousPage || state.pageInfo.startCursor == null) {
      return;
    }

    context.read<PlansBloc>().add(FindPreviousPlan(state));
  }

  void _onShowNextTrips(BuildContext context, PlansLoaded state) {
    if (!state.pageInfo.hasNextPage || state.pageInfo.endCursor == null) return;

    context.read<PlansBloc>().add(FindNextPlan(state));
  }
}
