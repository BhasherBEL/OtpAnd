import 'package:flutter/material.dart';
import 'package:otpand/objects/trip.dart';
import 'package:otpand/api/trip.dart';
import 'package:otpand/objects/timed_stop.dart';
import 'package:otpand/utils.dart';
import 'package:timelines_plus/timelines_plus.dart';

class TripPage extends StatelessWidget {
  final Trip trip;
  final String serviceDate;

  const TripPage({super.key, required this.trip, required this.serviceDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trip.headsign ?? 'Trip')),
      body: FutureBuilder<List<TimedStop>>(
        future: fetchTrip(trip, serviceDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }
          final stops = snapshot.data ?? [];
          if (stops.isEmpty) {
            return const Center(child: Text('No stops found for this trip.'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: 32,
                top: 16,
              ),
              child: FixedTimeline.tileBuilder(
                theme: TimelineThemeData(
                  nodePosition: 0,
                  color: Colors.blueAccent,
                  indicatorTheme: IndicatorThemeData(size: 26, position: 0),
                  connectorTheme: ConnectorThemeData(
                    thickness: 2.0,
                    color: Colors.blueAccent,
                  ),
                ),
                builder: TimelineTileBuilder.connected(
                  connectionDirection: ConnectionDirection.before,
                  itemCount: stops.length,
                  contentsBuilder: (context, index) {
                    final timedStop = stops[index];
                    final stop = timedStop.stop;

                    final arrivalTimeRt = timedStop.arrival.estimated?.time;
                    final arrivalTimeTheory = timedStop.arrival.scheduledTime;
                    final arrivalDelayed =
                        arrivalTimeRt != null &&
                        arrivalTimeRt != arrivalTimeTheory;

                    final departureTimeRt = timedStop.departure.estimated?.time;
                    final departureTimeTheory =
                        timedStop.departure.scheduledTime;
                    final departureDelayed =
                        departureTimeRt != null &&
                        departureTimeRt != departureTimeTheory;

                    final pastColor = Colors.grey;
                    final stopNameStyle = Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: timedStop.isPast() ? pastColor : null,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(stop.name, style: stopNameStyle),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Arrival time
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (arrivalDelayed)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        formatTime(arrivalTimeRt)!,
                                        style: TextStyle(
                                          color:
                                              timedStop.isPast()
                                                  ? pastColor
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    formatTime(arrivalTimeTheory) ?? '??:??',
                                    style: TextStyle(
                                      color:
                                          timedStop.isPast()
                                              ? pastColor
                                              : (arrivalTimeRt == null
                                                  ? Colors.grey.shade700
                                                  : Colors.green),
                                      decoration:
                                          arrivalDelayed
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              // Departure time
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (departureDelayed)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        formatTime(departureTimeRt)!,
                                        style: TextStyle(
                                          color:
                                              timedStop.isPast()
                                                  ? pastColor
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    formatTime(departureTimeTheory) ?? '??:??',
                                    style: TextStyle(
                                      color:
                                          timedStop.isPast()
                                              ? pastColor
                                              : (departureTimeRt == null
                                                  ? Colors.grey.shade700
                                                  : Colors.green),
                                      decoration:
                                          departureDelayed
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  indicatorBuilder: (context, index) {
                    final timedStop = stops[index];

                    final indicatorColor =
                        timedStop.isPast()
                            ? Colors.grey
                            : (index == 0
                                ? Colors.green
                                : (index == stops.length - 1
                                    ? Colors.red
                                    : Colors.blue));

                    if (index == 0) {
                      return DotIndicator(
                        size: 24,
                        color: indicatorColor,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.white,
                          size: 16,
                        ),
                      );
                    } else if (index == stops.length - 1) {
                      return DotIndicator(
                        size: 24,
                        color: indicatorColor,
                        child: Icon(Icons.flag, color: Colors.white, size: 16),
                      );
                    } else {
                      return OutlinedDotIndicator(
                        size: 20,
                        color: indicatorColor,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
