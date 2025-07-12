import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/pages/plan.dart';
import 'package:otpand/utils/extensions.dart';

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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planned journeys',
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
    return Card(
      elevation: 0,
      child: ListTile(
        title: Text('${plan.fromName} - ${plan.toName}'),
        subtitle: Text(_makeSubtitle()),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => PlanPage(plan: plan),
            ),
          );
        },
      ),
    );
  }

  String _makeSubtitle() {
    if (plan.startDateTime.daysDifference(plan.endDateTime) == 0) {
      return '${_makeDayText(plan.startDateTime)}${plan.startDateTime.hour}:${plan.startDateTime.minute} - ${plan.endDateTime.hour}:${plan.endDateTime.minute}';
    }
    return '${_makeDayText(plan.startDateTime)}${plan.startDateTime.hour}:${plan.startDateTime.minute} - ${_makeDayText(plan.endDateTime)}${plan.endDateTime.hour}:${plan.endDateTime.minute}';
  }

  String _makeDayText(DateTime date) {
    final diff = date.daysDifference(DateTime.now());

    if (diff == 0) {
      return '';
    } else if (diff == 1) {
      return 'Tomorrow, ';
    } else if (diff == -1) {
      return 'Yesterday, ';
    } else if (plan.startDateTime.year == DateTime.now().year) {
      return DateFormat('d MMM, ').format(plan.startDateTime);
    } else {
      return DateFormat('d MMM yyyy, ').format(plan.startDateTime);
    }
  }
}
