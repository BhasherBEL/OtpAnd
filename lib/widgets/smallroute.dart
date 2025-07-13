import 'dart:math';

import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/utils.dart';

class SmallRoute extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  final int? shortestPlan;
  final double? lowestEmissions;
  final int? lowestWalk;
  const SmallRoute({
    super.key,
    required this.plan,
    this.onTap,
    this.shortestPlan,
    this.lowestEmissions,
    this.lowestWalk,
  });

  bool _isFirstOfDay() {
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

  int _getWalkingDistance() {
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

    final bool isEcofriendliest = lowestEmissions != null &&
        (plan.getEmissions() < lowestEmissions! * 1.05 ||
            round(plan.getEmissions(), 1) == round(lowestEmissions!, 1));

    final ecoColor = lowestEmissions == null
        ? Colors.green.shade500
        : (() {
            final ecoRelative = lowestEmissions! / plan.getEmissions() / 2;
            final ecoAbsolute =
                plan.getFlightDistance() / plan.getEmissions() / 20000;
            final ecoScore = min(ecoRelative, 0.5) + min(ecoAbsolute, 0.5);
            return Color.lerp(
                Colors.red.shade500, Colors.green.shade500, ecoScore);
          })();

    final bool isShortest = shortestPlan != null &&
        (plan.getDuration() < shortestPlan! * 1.05 ||
            round(plan.getDuration(), 1) == round(shortestPlan!, 1));

    final int walkingDistance = _getWalkingDistance();
    final bool isLowestWalk = lowestWalk != null &&
        (walkingDistance < lowestWalk! * 1.05 ||
            round(walkingDistance, 1) == round(lowestWalk!, 1));

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < filteredLegs.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: widths[i],
                            child: (() {
                              final leg = filteredLegs[i];
                              if (leg.transitLeg && i > 0) {
                                int prevTransitIdx = i - 1;
                                while (prevTransitIdx >= 0 &&
                                    !filteredLegs[prevTransitIdx].transitLeg) {
                                  prevTransitIdx--;
                                }
                                if (prevTransitIdx >= 0) {
                                  final prevLeg = filteredLegs[prevTransitIdx];
                                  final prevArrival =
                                      prevLeg.to.arrival?.scheduledTime;
                                  final currDeparture =
                                      leg.from.departure?.scheduledTime;
                                  if (prevArrival != null &&
                                      currDeparture != null) {
                                    final prev = DateTime.tryParse(prevArrival);
                                    final curr =
                                        DateTime.tryParse(currDeparture);
                                    if (prev != null && curr != null) {
                                      final gap =
                                          curr.difference(prev).inMinutes;
                                      if (gap > 0 && gap < 180) {
                                        double leftOffset = -20;
                                        if (i > 0 &&
                                            filteredLegs[i - 1].mode ==
                                                'WALK' &&
                                            filteredLegs[i - 1].distance <
                                                100) {
                                          leftOffset = -27;
                                        }
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            _LegTile(leg: leg),
                                            Positioned(
                                              top: -10,
                                              left: leftOffset,
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withOpacity(0.7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.schedule,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        gap.toString(),
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    }
                                  }
                                }
                              }
                              return _LegTile(leg: leg);
                            })(),
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
                              TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          mode,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ' at ',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          depTime,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ' from stop ',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Expanded(
                          child: Text(
                            stopName,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
                      color: isLowestWalk ? Colors.purple.shade100 : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_walk,
                            color: Colors.purple.shade500),
                        const SizedBox(width: 2),
                        Text(
                          displayDistanceShort(walkingDistance),
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
