import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/pages/trip.dart';
import 'package:otpand/pages/stop.dart';
import 'package:otpand/pages/plan/other_departures.dart';
import 'package:otpand/widgets/route_icon.dart';
import 'package:otpand/widgets/intermediate_stops.dart';

class PlanTimeline extends StatelessWidget {
  final Plan plan;
  const PlanTimeline({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final legs = plan.legs;
    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        color: Colors.blueAccent,
        indicatorTheme: IndicatorThemeData(
          size: 26,
          position: 0,
        ),
        connectorTheme: ConnectorThemeData(
          thickness: 2.0,
          color: Colors.blueAccent,
        ),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.before,
        itemCount: legs.length + 1,
        contentsBuilder: (context, index) {
          final leg = index < legs.length ? legs[index] : null;
          final previousLeg = index > 0 ? legs[index - 1] : null;
          final place = leg?.from ?? previousLeg!.to;
          final departureTimeRt = leg?.from.departure?.estimated?.time;
          final departureTimeTheory = leg?.from.departure?.scheduledTime;
          final departureTime = departureTimeRt ?? departureTimeTheory;
          final departureDelayed = departureTimeRt != null && departureTimeRt != departureTimeTheory;
          final arrivalTimeRt = previousLeg?.to.arrival?.estimated?.time;
          final arrivalTimeTheory = previousLeg?.to.arrival?.scheduledTime;
          final arrivalTime = arrivalTimeRt ?? arrivalTimeTheory;
          final arrivalDelayed = arrivalTimeRt != null && arrivalTimeRt != arrivalTimeTheory;
          final transferTime = arrivalTime != null && parseTime(arrivalTime) != null && parseTime(departureTime) != null
              ? parseTime(departureTime)!.difference(parseTime(arrivalTime)!).inSeconds
              : null;
          final hasTransfer = transferTime != null && transferTime > 0;
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: (leg?.transitLeg == true || (leg == null && previousLeg?.transitLeg == true))
                          ? GestureDetector(
                              onTap: () {
                                if (place.stop != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => StopPage(stop: place.stop!),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                place.stop != null && place.stop!.platformCode != null
                                    ? '${place.name} (Platform ${place.stop!.platformCode})'
                                    : place.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500, decoration: TextDecoration.underline, decorationColor: Colors.grey),
                              ),
                            )
                          : Text(
                              place.stop != null && place.stop!.platformCode != null
                                  ? '${place.name} (Platform ${place.stop!.platformCode})'
                                  : place.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                    ),
                    if (hasTransfer)
                      _buildTransferBadge(context, transferTime, leg, previousLeg),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasTransfer || leg == null || (previousLeg != null && previousLeg.transitLeg))
                          Row(
                            children: [
                              if (arrivalDelayed)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    formatTime(arrivalTimeRt)!,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              Text(
                                formatTime(arrivalTimeTheory) ?? '??:??',
                                style: TextStyle(
                                  color: arrivalTimeRt == null ? Colors.grey.shade700 : Colors.green,
                                  decoration: arrivalDelayed ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        if (hasTransfer)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_downward, size: 12),
                          ),
                        if (hasTransfer || (leg != null && leg.transitLeg) || previousLeg == null)
                          Row(
                            children: [
                              if (departureDelayed)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    formatTime(departureTimeRt)!,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              Text(
                                formatTime(departureTimeTheory) ?? '??:??',
                                style: TextStyle(
                                  color: departureTimeRt == null ? Colors.grey.shade700 : Colors.green,
                                  decoration: departureDelayed ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                if (leg != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: leg.trip != null && leg.serviceDate != null
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => TripPage(
                                        trip: leg.trip!,
                                        serviceDate: leg.serviceDate!,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (leg.route != null) RouteIconWidget(route: leg.route!),
                              Expanded(
                                child: Text(
                                  leg.transitLeg
                                      ? leg.headsign ?? leg.route?.longName ?? 'Unknown'
                                      : '${displayDistance(leg.distance)} - ${displayTime(leg.duration)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    decoration: leg.trip != null ? TextDecoration.underline : null,
                                    decorationColor: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (leg.otherDepartures.isNotEmpty) OtherDeparturesWidget(leg: leg),
                        if (leg.transitLeg)
                          IntermediateStopsWidget(
                            stops: leg.intermediateStops,
                            leg: leg,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
        indicatorBuilder: (context, index) {
          if (index == 0) {
            return const DotIndicator(
              size: 24,
              color: Colors.green,
              child: Icon(
                Icons.location_pin,
                color: Colors.white,
                size: 16,
              ),
            );
          } else if (index == legs.length) {
            return const DotIndicator(
              size: 24,
              color: Colors.red,
              child: Icon(
                Icons.flag,
                color: Colors.white,
                size: 16,
              ),
            );
          } else {
            return const OutlinedDotIndicator(
              size: 20,
              color: Colors.blue,
              backgroundColor: Colors.white,
              borderWidth: 2.0,
            );
          }
        },
        connectorBuilder: (context, index, type) {
          if (index == 0) {
            return null;
          }
          return const SolidLineConnector();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transfer risk helpers — used by PlanTimeline
// ---------------------------------------------------------------------------

Color _transferFg(double r) => transferReliabilityFg(r);
Color _transferBg(double r) => transferReliabilityBg(r);
Color _nextFg(double r) => transferReliabilityFg(r);
Color _nextBg(double r) => transferReliabilityBg(r);

/// Human-readable label for a transit leg: short name when available,
/// otherwise the mode capitalized (e.g. "Bus", "Tram").
String _legLabel(Leg leg) {
  final short = leg.route?.shortName;
  if (short != null && short.isNotEmpty) return short;
  final m = leg.mode;
  return m[0] + m.substring(1).toLowerCase();
}

/// Returns the effective minimum wait in seconds if a connection is missed:
/// the lesser of the same-route next departure and any cross-route alternative
/// in [leg.otherDepartures] that departs after this leg.
int? _effectiveWaitSecs(TransferRisk risk, Leg leg) {
  final sameRoute = risk.waitIfMissedSecs;
  final crossRoute = leg.soonestNextDepartureWaitSecs;
  if (sameRoute == null) return crossRoute;
  if (crossRoute == null) return sameRoute;
  return sameRoute < crossRoute ? sameRoute : crossRoute;
}

/// Computes the clock time of the next departure after a missed connection,
/// using the effective minimum wait (same-route or cross-route alternative).
/// Returns null when there is no next departure or the scheduled time is
/// unavailable.
String? _nextDepartureTime(TransferRisk risk, Leg leg) {
  final waitSecs = _effectiveWaitSecs(risk, leg);
  if (waitSecs == null) return null;
  final isoStr = leg.from.departure?.scheduledTime;
  if (isoStr == null) return null;
  final dt = DateTime.tryParse(isoStr);
  if (dt == null) return null;
  return formatTime(dt.add(Duration(seconds: waitSecs)).toIso8601String());
}

/// Transfers under this threshold are flagged even when the backend provides
/// no reliability data.
const int _tightTransferSecs = 5 * 60;

/// A transfer is worth flagging when either:
/// - reliability < 90 %, OR
/// - missing it means a wait > 20 min or no more service today.
///
/// The second condition matters even for high-reliability connections: a 95 %
/// chance is fine in isolation, but if the fallback is 45 min away the stakes
/// are high enough to show the score.
bool _isTransferRisky(TransferRisk risk, Leg leg) {
  final effectiveWait = _effectiveWaitSecs(risk, leg);
  return risk.reliability < 0.95 ||
      effectiveWait == null ||
      effectiveWait > 20 * 60;
}

/// Inline transfer time indicator.
/// - Gray italic text: no risk data + ≥ 5 min gap, or backend says not risky.
/// - Plain amber chip (⚠ time): tight gap but no backend data.
/// - Colored chip (⚠ NN%  time): backend reports a risky transfer.
Widget _buildTransferBadge(
    BuildContext context, int transferSecs, Leg? leg, Leg? previousLeg) {
  final risk = leg?.transferRisk;
  final timeStr = displayTime(transferSecs);

  // No backend data and comfortable gap: plain text.
  if (risk == null && transferSecs >= _tightTransferSecs) {
    return Text(
      timeStr,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontStyle: FontStyle.italic,
        fontSize: 12,
      ),
    );
  }

  // Backend data present but not risky: plain text.
  if (risk != null && leg != null && !_isTransferRisky(risk, leg)) {
    return Text(
      timeStr,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontStyle: FontStyle.italic,
        fontSize: 12,
      ),
    );
  }

  // No backend data but transfer is tight: amber chip, time only, no tap.
  if (risk == null) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: Colors.amber.shade800.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 11, color: Colors.amber.shade800),
          const SizedBox(width: 3),
          Text(
            timeStr,
            style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade800,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  final fg = _transferFg(risk.reliability);
  final bg = _transferBg(risk.reliability);
  final waitSecs = leg != null ? _effectiveWaitSecs(risk, leg) : risk.waitIfMissedSecs;
  // Only show same-route next-reliability when same-route is the soonest option.
  final sameRouteIsSoonest = leg == null ||
      leg.soonestNextDepartureWaitSecs == null ||
      (risk.waitIfMissedSecs != null &&
          risk.waitIfMissedSecs! <= leg.soonestNextDepartureWaitSecs!);
  final nextR = sameRouteIsSoonest ? risk.nextReliability : null;

  // Build the top (current) row — always present in the risky branch.
  Widget topRow = Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.warning_amber_rounded, size: 11, color: fg),
      const SizedBox(width: 3),
      Text(
        '${(risk.reliability * 100).round()}%',
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.bold),
      ),
      Text(
        '  $timeStr',
        style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.8)),
      ),
    ],
  );

  // Split badge when the next departure's reliability is known.
  final bool showSplit = nextR != null && waitSecs != null;

  if (showSplit) {
    final nfg = _nextFg(nextR);
    final nbg = _nextBg(nextR);
    return GestureDetector(
      onTap: () => _showTransferRiskSheet(context, risk, leg!, previousLeg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: fg.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: bg,
              child: topRow,
            ),
            Container(height: 0.5, color: fg.withValues(alpha: 0.25)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: nbg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(nextR * 100).round()}%',
                    style: TextStyle(
                        fontSize: 12, color: nfg, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '  +${displayTime(waitSecs)}',
                    style:
                        TextStyle(fontSize: 11, color: nfg.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  return GestureDetector(
    onTap: () => _showTransferRiskSheet(context, risk, leg!, previousLeg),
    child: Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.4), width: 0.5),
      ),
      child: topRow,
    ),
  );
}

/// Modal bottom sheet with full connection-risk detail.
void _showTransferRiskSheet(
    BuildContext context, TransferRisk risk, Leg leg, Leg? previousLeg) {
  final pct = (risk.reliability * 100).round();
  final barColor = _transferFg(risk.reliability);
  final waitSecs = _effectiveWaitSecs(risk, leg);
  final nextClockTime = _nextDepartureTime(risk, leg);
  final sameRouteIsSoonest = leg.soonestNextDepartureWaitSecs == null ||
      (risk.waitIfMissedSecs != null &&
          risk.waitIfMissedSecs! <= leg.soonestNextDepartureWaitSecs!);
  // Show the route of whichever departure is actually soonest.
  final nextLeg = sameRouteIsSoonest ? leg : (leg.soonestNextDepartureLeg ?? leg);

  showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Text(
              'Transfer at ${leg.from.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // ── From → To with scheduled times ───────────────────────────
            if (previousLeg != null) ...[
              Row(
                children: [
                  _RoutePill(leg: previousLeg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                  ),
                  _RoutePill(leg: leg),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'arrives ${formatTime(previousLeg.to.arrival?.scheduledTime) ?? '??:??'}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Text(
                    '  ·  ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'departs ${formatTime(leg.from.departure?.scheduledTime) ?? '??:??'}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Reliability ───────────────────────────────────────────────
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
                    'chance of making this connection',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: risk.reliability,
              color: barColor,
              backgroundColor: Colors.grey.shade200,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // ── Fallback ──────────────────────────────────────────────────
            if (waitSecs != null) ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 2,
                children: [
                  const Text('If missed:',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const Text('next', style: TextStyle(fontSize: 13)),
                  _RoutePill(leg: nextLeg),
                  Text('${displayTime(waitSecs)} later',
                      style: const TextStyle(fontSize: 13)),
                  if (nextClockTime != null)
                    Text('($nextClockTime)',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              if (risk.nextReliability != null && sameRouteIsSoonest) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(risk.nextReliability! * 100).round()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _nextFg(risk.nextReliability!),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'chance of catching the next departure',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: risk.nextReliability,
                  color: _nextFg(risk.nextReliability!),
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ] else
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 2,
                children: [
                  const Text('If missed:',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  _RoutePill(leg: leg),
                  const Text('no more departures today',
                      style: TextStyle(fontSize: 13, color: Colors.red)),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

/// Small colored pill showing the route short name (or mode) for a leg.
class _RoutePill extends StatelessWidget {
  final Leg leg;
  const _RoutePill({required this.leg});

  @override
  Widget build(BuildContext context) {
    final bg = leg.color;
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _legLabel(leg),
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
