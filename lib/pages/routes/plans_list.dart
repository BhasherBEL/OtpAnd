import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otpand/blocs/plans/bloc.dart';
import 'package:otpand/blocs/plans/events.dart';
import 'package:otpand/blocs/plans/states.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/pages/route.dart';
import 'package:otpand/widgets/smallroute.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 150),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state is PlansLoadingPrevious)
            CircularProgressIndicator()
          else if (loadedState.pageInfo.hasPreviousPage)
            TextButton(
              onPressed: () => _onShowEarlierTrips(context, loadedState),
              child: Text('Show earlier trips'),
            ),
          if (loadedState.plans.isEmpty)
            Text('No plans found.')
          else
            ..._buildPlansList(loadedState.plans, context),
          if (state is PlansLoadingNext)
            CircularProgressIndicator()
          else if (loadedState.pageInfo.hasNextPage)
            TextButton(
              onPressed: () => _onShowNextTrips(context, loadedState),
              child: Text('Show next trips'),
            ),
        ],
      ),
    );
  }

  Iterable<Widget> _buildPlansList(List<Plan> plans, BuildContext context) {
    final shortestPlan =
        plans.reduce((p1, p2) => p1.getDuration() < p2.getDuration() ? p1 : p2);
    final double lowestEmissions = plans
        .reduce((p1, p2) => p1.getEmissions() < p2.getEmissions() ? p1 : p2)
        .getEmissions();

    plans.sort((a, b) {
      if (a.end == null && b.end == null) return 0;
      if (a.end == null) return 1;
      if (b.end == null) return -1;
      if (a.end == b.end) return 0;

      final aTime = DateTime.tryParse(a.end!) ?? DateTime.now();
      final bTime = DateTime.tryParse(b.end!) ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    return plans.map((plan) {
      return SmallRoute(
        plan: plan,
        isShortest: plan == shortestPlan,
        lowestEmissions: lowestEmissions,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => RoutePage(plan: plan)),
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
