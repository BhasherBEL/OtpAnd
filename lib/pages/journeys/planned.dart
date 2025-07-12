import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otpand/db/crud/plans.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/pages/plan.dart';
import 'package:otpand/utils/extensions.dart';
import 'package:otpand/widgets/smallroute.dart';

class PlannedWidget extends StatefulWidget {
  const PlannedWidget({super.key});

  @override
  State<PlannedWidget> createState() => _PlannedWidgetState();
}

class _PlannedWidgetState extends State<PlannedWidget> {
  List<Plan> plannedPlans = Plan.currentPlanneds.value;

  @override
  void initState() {
    super.initState();
    Plan.currentPlanneds.addListener(_loadPlanneds);
  }

  @override
  void dispose() {
    Plan.currentPlanneds.removeListener(_loadPlanneds);
    super.dispose();
  }

  void _loadPlanneds() {
    setState(() {
      plannedPlans = Plan.currentPlanneds.value
          .where((plan) => plan.endDateTime
              .isAfter(DateTime.now().subtract(const Duration(hours: 1))))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (plannedPlans.isEmpty) {
      return const SizedBox();
    }

    final soonPlanned = plannedPlans.take(5).toList();

    soonPlanned.sort((a, b) {
      final aDate = a.startDateTime;
      final bDate = b.startDateTime;
      return aDate.isBefore(bDate) ? -1 : (aDate.isAfter(bDate) ? 1 : 0);
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming journeys',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: soonPlanned.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final plan = soonPlanned[index];
              return _PlanedCard(
                plan: plan,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlanedCard extends StatelessWidget {
  final Plan plan;
  const _PlanedCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        if (plan.id == null) return;
        await PlanDao().deletePlan(plan.id!);
        await PlanDao().loadAll();
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        child: SmallRoute(
          plan: plan,
          shortestPlan: 0,
          lowestWalk: 0,
          lowestEmissions: 0,
          lowestTransfers: 0,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => PlanPage(plan: plan),
              ),
            );
          },
        ),
      ),
    );
  }
}
