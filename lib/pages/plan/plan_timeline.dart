import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/utils.dart';
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
                      Text(
                        displayTime(transferTime),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
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

