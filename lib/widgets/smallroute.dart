import 'dart:math';

import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/utils.dart';

Color _transferFg(double r) {
  if (r >= 0.9) return Colors.amber.shade800;
  if (r >= 0.7) return Colors.orange.shade800;
  if (r >= 0.5) return Colors.deepOrange.shade800;
  return Colors.red.shade800;
}

Color _transferBg(double r) {
  if (r >= 0.9) return Colors.amber.shade50;
  if (r >= 0.7) return Colors.orange.shade50;
  if (r >= 0.5) return Colors.deepOrange.shade50;
  return Colors.red.shade50;
}

Color _nextFg(double r) {
  if (r >= 0.9) return Colors.green.shade700;
  return _transferFg(r);
}

/// Effective minimum wait if a connection is missed: lesser of same-route
/// next departure and any cross-route alternative in [leg.otherDepartures].
int? _effectiveWaitSecs(TransferRisk risk, Leg leg) {
  final sameRoute = risk.waitIfMissedSecs;
  final crossRoute = leg.soonestNextDepartureWaitSecs;
  if (sameRoute == null) return crossRoute;
  if (crossRoute == null) return sameRoute;
  return sameRoute < crossRoute ? sameRoute : crossRoute;
}

/// Mirrors the same predicate in plan_timeline.dart.
bool _isTransferRisky(TransferRisk risk, Leg leg) {
  final effectiveWait = _effectiveWaitSecs(risk, leg);
  return risk.reliability < 0.95 ||
      effectiveWait == null ||
      effectiveWait > 20 * 60;
}

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

  /// Frontend approximation of joint journey reliability: product of per-leg
  /// reliabilities. Returns null when no leg carries risk data.
  ///
  /// TODO(backend): maas-rs should compute and expose the true joint
  /// reliability so the frontend does not have to approximate it.
  double? _planReliability() {
    final risks = plan.legs
        .where((l) => l.transitLeg && l.transferRisk != null)
        .map((l) => l.transferRisk!.reliability)
        .toList();
    if (risks.isEmpty) return null;
    return risks.fold<double>(1.0, (acc, r) => acc * r);
  }

  /// Whether any transit leg in this plan has a risky transfer.
  bool _hasRiskyTransfer() => plan.legs.any(
      (l) => l.transitLeg && l.transferRisk != null && _isTransferRisky(l.transferRisk!, l));

  /// Whether the plan contains at least one transfer between transit legs
  /// (i.e. two or more transit legs, possibly separated by a walk).
  bool _hasTransfers() => plan.legs.where((l) => l.transitLeg).length > 1;

  void _showPlanRiskSheet(BuildContext context, double planReliability) {
    final riskyLegs = plan.legs
        .where((l) =>
            l.transitLeg &&
            l.transferRisk != null &&
            _isTransferRisky(l.transferRisk!, l))
        .toList();
    final pct = (planReliability * 100).round();
    final barColor = _transferFg(planReliability);

    // Build a map from each transit leg to the previous transit leg so we can
    // show "Route A → Route B" in each row.
    final Map<Leg, Leg?> prevTransit = {};
    Leg? lastTransit;
    for (final l in plan.legs) {
      if (l.transitLeg) {
        prevTransit[l] = lastTransit;
        lastTransit = l;
      }
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              const Text(
                'Journey reliability',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'chance of completing as planned',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: planReliability,
                color: barColor,
                backgroundColor: Colors.grey.shade200,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 16),
              const Divider(),

              // ── Per-transfer rows ───────────────────────────────────────
              ...riskyLegs.map((leg) {
                final risk = leg.transferRisk!;
                final legPct = (risk.reliability * 100).round();
                final legColor = _transferFg(risk.reliability);
                final waitSecs = _effectiveWaitSecs(risk, leg);
                final prev = prevTransit[leg];
                final nextClockTime = _nextDepartureClockTime(risk, leg);
                final sameRouteIsSoonest =
                    leg.soonestNextDepartureWaitSecs == null ||
                    (risk.waitIfMissedSecs != null &&
                        risk.waitIfMissedSecs! <=
                            leg.soonestNextDepartureWaitSecs!);
                final nextLeg = sameRouteIsSoonest
                    ? leg
                    : (leg.soonestNextDepartureLeg ?? leg);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Route A → Route B
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Route A → Route B  at Stop"
                            Row(
                              children: [
                                if (prev != null) ...[
                                  _SmallRoutePill(leg: prev),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.arrow_forward,
                                        size: 12, color: Colors.grey),
                                  ),
                                ],
                                _SmallRoutePill(leg: leg),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'at ${leg.from.name}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            // "arrives HH:MM  ·  departs HH:MM"
                            if (prev?.to.arrival?.scheduledTime != null ||
                                leg.from.departure?.scheduledTime != null)
                              Text(
                                [
                                  if (prev?.to.arrival?.scheduledTime != null)
                                    'arrives ${formatTime(prev!.to.arrival!.scheduledTime)}',
                                  if (leg.from.departure?.scheduledTime !=
                                      null)
                                    'departs ${formatTime(leg.from.departure!.scheduledTime)}',
                                ].join('  ·  '),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            const SizedBox(height: 3),
                            // "If missed: next [ROUTE] Xm later (HH:MM)"
                            if (waitSecs != null)
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  const Text('If missed:',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  const Text('next',
                                      style: TextStyle(fontSize: 12)),
                                  _SmallRoutePill(leg: nextLeg),
                                  Text('${displayTime(waitSecs)} later',
                                      style:
                                          const TextStyle(fontSize: 12)),
                                  if (nextClockTime != null)
                                    Text('($nextClockTime)',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                ],
                              )
                            else
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  const Text('If missed:',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  _SmallRoutePill(leg: leg),
                                  const Text('no more departures today',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Reliability % (current top, next bottom)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$legPct%',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: legColor,
                                  fontSize: 15),
                            ),
                            if (risk.nextReliability != null && sameRouteIsSoonest)
                              Text(
                                '${(risk.nextReliability! * 100).round()}%',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _nextFg(risk.nextReliability!),
                                    fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Clock time of the next departure after a missed connection, using the
  /// effective minimum wait (same-route or cross-route alternative).
  String? _nextDepartureClockTime(TransferRisk risk, Leg leg) {
    final waitSecs = _effectiveWaitSecs(risk, leg);
    if (waitSecs == null) return null;
    final isoStr = leg.from.departure?.scheduledTime;
    if (isoStr == null) return null;
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return null;
    return formatTime(dt.add(Duration(seconds: waitSecs)).toIso8601String());
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
                                        final risk = leg.transferRisk;
                                        final isRisky = risk != null &&
                                            _isTransferRisky(risk, leg);
                                        final chipBg = isRisky
                                            ? _transferFg(risk.reliability)
                                            : Colors.grey.withValues(alpha: 0.7);
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
                                                    color: chipBg,
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
              Builder(
                builder: (context) {
                  final planReliability = _planReliability();
                  final showRisk = _hasRiskyTransfer() ||
                      (planReliability != null && planReliability < 0.95);
                  final showUnknown =
                      planReliability == null && _hasTransfers();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                        margin: (showRisk && planReliability != null) || showUnknown
                            ? EdgeInsets.zero
                            : const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isEcofriendliest
                              ? Colors.green.shade100
                              : null,
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
                      if (showRisk && planReliability != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _showPlanRiskSheet(context, planReliability),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _transferBg(planReliability),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: _transferFg(planReliability)
                                      .withValues(alpha: 0.4),
                                  width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined,
                                    color: _transferFg(planReliability),
                                    size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '${(planReliability * 100).round()}%',
                                  style: TextStyle(
                                      color: _transferFg(planReliability)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (showUnknown) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.grey.shade400, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: Colors.grey.shade600, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                '?',
                                style:
                                    TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
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

/// Small colored route pill used in the plan risk sheet.
class _SmallRoutePill extends StatelessWidget {
  final Leg leg;
  const _SmallRoutePill({required this.leg});

  @override
  Widget build(BuildContext context) {
    final bg = leg.color;
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final short = leg.route?.shortName;
    final label = short != null && short.isNotEmpty
        ? short
        : leg.mode[0] + leg.mode.substring(1).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
