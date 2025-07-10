import 'dart:math';

import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/utils.dart';

class SmallRoute extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  final int shortestPlan;
  final double lowestEmissions;
  const SmallRoute({
    super.key,
    required this.plan,
    this.onTap,
    required this.shortestPlan,
    required this.lowestEmissions,
  });

  bool _isFirstOfDay() {
    // Find the first transit leg with other departures
    final transitLegs = plan.legs
        .where((leg) =>
            leg.transitLeg &&
            leg.otherDepartures.isNotEmpty &&
            leg.from.departure?.scheduledTime != null &&
            leg.serviceDate != null)
        .toList();

    if (transitLegs.isEmpty) return false;

    final firstTransitLeg = transitLegs.first;
    final currentDeparture = firstTransitLeg.from.departure!.scheduledTime!;
    final currentServiceDate = firstTransitLeg.serviceDate!;

    // Check if current departure is earlier than all other departures on the same service date
    for (final otherLeg in firstTransitLeg.otherDepartures) {
      if (otherLeg.from.departure?.scheduledTime != null &&
          otherLeg.serviceDate == currentServiceDate) {
        final otherTime = otherLeg.from.departure!.scheduledTime!;
        if (DateTime.parse(otherTime)
            .isBefore(DateTime.parse(currentDeparture))) {
          return false;
        }
      }
    }

    return true;
  }

  bool _isLastOfDay() {
    // Find the first transit leg with other departures
    final transitLegs = plan.legs
        .where((leg) =>
            leg.transitLeg &&
            leg.otherDepartures.isNotEmpty &&
            leg.from.departure?.scheduledTime != null &&
            leg.serviceDate != null)
        .toList();

    if (transitLegs.isEmpty) return false;

    final firstTransitLeg = transitLegs.first;
    final currentDeparture = firstTransitLeg.from.departure!.scheduledTime!;
    final currentServiceDate = firstTransitLeg.serviceDate!;

    // Check if current departure is later than all other departures on the same service date
    for (final otherLeg in firstTransitLeg.otherDepartures) {
      if (otherLeg.from.departure?.scheduledTime != null &&
          otherLeg.serviceDate == currentServiceDate) {
        final otherTime = otherLeg.from.departure!.scheduledTime!;
        if (DateTime.parse(otherTime)
            .isAfter(DateTime.parse(currentDeparture))) {
          return false;
        }
      }
    }

    return true;
  }

  int _getTransferCount() {
    // Count the number of transfers (transitions between different transit routes)
    final transitLegs = plan.legs.where((leg) => leg.transitLeg).toList();

    if (transitLegs.length <= 1) return 0;

    int transfers = 0;
    for (int i = 1; i < transitLegs.length; i++) {
      // Check if this is a different route from the previous one
      final prevRoute = transitLegs[i - 1].route?.shortName ?? '';
      final currentRoute = transitLegs[i].route?.shortName ?? '';
      if (prevRoute != currentRoute) {
        transfers++;
      }
    }

    return transfers;
  }

  int _getWalkingDistance() {
    // Sum up distances from walking, biking, and driving legs
    return plan.legs
        .where((leg) =>
            leg.mode == 'WALK' || leg.mode == 'BICYCLE' || leg.mode == 'CAR')
        .fold<int>(0, (sum, leg) => sum + leg.distance.round());
  }

  @override
  Widget build(BuildContext context) {
    final filteredLegs = <Leg>[];
    for (int i = 0; i < plan.legs.length; i++) {
      final leg = plan.legs[i];
      if (i > 0 &&
          leg.mode == 'WALK' &&
          (plan.legs[i - 1].mode == 'BICYCLE' ||
              plan.legs[i - 1].mode == 'CAR') &&
          leg.distance < 100) {
        continue;
      }
      filteredLegs.add(leg);
    }

    if (filteredLegs.isEmpty) {
      filteredLegs.add(plan.legs.first);
    }

    final departure =
        formatTime(filteredLegs.first.from.departure?.scheduledTime) ?? '--:--';
    final arrival =
        formatTime(filteredLegs.last.to.arrival?.scheduledTime) ?? '--:--';
    final duration = displayTimeShortVague(
      calculateDurationFromString(
        filteredLegs.first.from.departure?.scheduledTime,
        filteredLegs.last.to.arrival?.scheduledTime,
      ),
    );

    final bool isEcofriendliest =
        plan.getEmissions() < lowestEmissions * 1.05 ||
            round(plan.getEmissions(), 1) == round(lowestEmissions, 1);
    final ecoRelative = lowestEmissions / plan.getEmissions() / 2;
    final ecoAbsolute = plan.getFlightDistance() / plan.getEmissions() / 20000;
    final ecoScore = min(ecoRelative, 0.5) + min(ecoAbsolute, 0.5);
    final ecoColor =
        Color.lerp(Colors.red.shade500, Colors.green.shade500, ecoScore);

    final bool isShortest = plan.getDuration() < shortestPlan * 1.05 ||
        round(plan.getDuration(), 1) == round(shortestPlan, 1);
    final bool isFirstOfDay = _isFirstOfDay();
    final bool isLastOfDay = _isLastOfDay();

    return Card(
      color: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        departure,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isFirstOfDay) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                                color: Colors.orange.shade300, width: 0.5),
                          ),
                          child: Text(
                            'First Departure',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                      if (isLastOfDay) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                                color: Colors.purple.shade300, width: 0.5),
                          ),
                          child: Text(
                            'Last departure',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    arrival,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final minWidths = filteredLegs.map((leg) {
                    if ((leg.mode == 'WALK' || leg.mode == 'BICYCLE') &&
                        leg.distance < 100) {
                      return 8.0;
                    } else if (leg.mode == 'WALK' || leg.mode == 'BICYCLE') {
                      return 25.0 +
                          (leg.distance.round().toString().length * 10);
                    } else {
                      return 48.0 + ((leg.route?.shortName ?? '').length * 10);
                    }
                  }).toList();

                  final totalMinWidth = minWidths.fold<double>(
                    0,
                    (a, b) => a + b,
                  );

                  final availableWidth = constraints.maxWidth;

                  final totalHorizontalPadding = 2.0 * 2 * filteredLegs.length;
                  final adjustedAvailableWidth =
                      (availableWidth - totalHorizontalPadding)
                          .clamp(0.0, double.infinity);
                  final extraWidth = (adjustedAvailableWidth > totalMinWidth)
                      ? adjustedAvailableWidth - totalMinWidth
                      : 0.0;

                  final totalDuration = filteredLegs.fold<num>(
                    0,
                    (sum, leg) => sum + leg.duration,
                  );

                  final widths = <double>[];
                  for (int i = 0; i < filteredLegs.length; i++) {
                    final proportion =
                        (filteredLegs[i].duration / totalDuration).toDouble();
                    final addWidth = extraWidth * proportion;
                    widths.add(minWidths[i] + addWidth);
                  }

                  final row = Row(
                    children: [
                      for (int i = 0; i < filteredLegs.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: widths[i],
                            child: _LegTile(leg: filteredLegs[i]),
                          ),
                        ),
                    ],
                  );

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: totalMinWidth),
                      child: row,
                    ),
                  );
                },
              ),
              // Insert transit departure row if applicable
              Builder(
                builder: (context) {
                  Leg? firstTransitLeg;
                  try {
                    firstTransitLeg =
                        plan.legs.firstWhere((leg) => leg.transitLeg);
                  } on StateError {
                    firstTransitLeg = null;
                  }
                  if (firstTransitLeg == null) return const SizedBox.shrink();
                  final mode = firstTransitLeg.mode.toLowerCase();
                  final depTime = formatTime(
                          firstTransitLeg.from.departure?.scheduledTime) ??
                      '--:--';
                  final stopName = firstTransitLeg.from.stop?.name ??
                      firstTransitLeg.from.name;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Departing by ',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
                        ),
                        Text(
                          mode,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ' at ',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
                        ),
                        Text(
                          depTime,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ' from stop ',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
                        ),
                        Text(
                          stopName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isShortest ? Colors.blue.shade100 : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timelapse, color: Colors.blue.shade500),
                        const SizedBox(width: 2),
                        Text(
                          duration,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz_sharp,
                            color: Colors.orange.shade500),
                        const SizedBox(width: 2),
                        Text(
                          _getTransferCount().toString(),
                          style: TextStyle(
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_walk,
                            color: Colors.purple.shade500),
                        const SizedBox(width: 2),
                        Text(
                          displayDistanceShort(_getWalkingDistance()),
                          style: TextStyle(
                            color: Colors.purple.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isEcofriendliest ? Colors.green.shade100 : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.eco, color: ecoColor),
                        const SizedBox(width: 2),
                        Text(
                          '${round(plan.getEmissions(), 1)}kg CO₂e',
                          style: TextStyle(
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _LegTile extends StatelessWidget {
  final Leg leg;

  const _LegTile({required this.leg});

  @override
  Widget build(BuildContext context) {
    final bgColor = leg.color;

    if ((leg.mode == 'WALK' || leg.mode == 'BICYCLE') && leg.distance < 100) {
      return Container(
        width: 8,
        height: 25,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final textColor = leg.route?.textColor ??
        (ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
            ? Colors.white
            : Colors.black);

    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconForMode(leg.mode), size: 18, color: textColor),
          const SizedBox(width: 4),
          Text(
            (leg.mode == 'WALK' || leg.mode == 'BICYCLE')
                ? displayTimeShort(leg.duration)
                : leg.route?.shortName ?? '',
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
