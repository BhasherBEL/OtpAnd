import 'package:flutter/material.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/utils.dart';
import 'package:timelines_plus/timelines_plus.dart';

class RoutePage extends StatelessWidget {
  const RoutePage({super.key, required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final legs = plan.legs;

    return Scaffold(
      appBar: AppBar(title: Text("Journey Details")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // TITLE BAR
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        legs.first.from.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        "${formatTime(legs.first.from.departure?.scheduledTime) ?? ''} → "
                        "${formatTime(legs.last.to.arrival?.scheduledTime) ?? ''}",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18), // spacer
                  FixedTimeline.tileBuilder(
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
                      itemCount: legs.length + 1,
                      contentsBuilder: (context, index) {
                        if (index < legs.length) {
                          final leg = legs[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 18.0,
                              bottom: 4.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(leg.from.name),
                                    Text(
                                      formatTime(
                                            leg.from.departure?.scheduledTime,
                                          ) ??
                                          '??:??',
                                    ),
                                  ],
                                ),
                                Card(
                                  color: Colors.grey.shade100,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    iconForMode(leg.mode),
                                                    color: colorForMode(
                                                      leg.mode,
                                                    ),
                                                  ),
                                                  if (leg.route?.shortName !=
                                                      null) ...[
                                                    const SizedBox(width: 6),
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      child: ColoredBox(
                                                        color:
                                                            leg.route?.color ??
                                                            colorForMode(
                                                              leg.mode,
                                                            ),
                                                        child: SizedBox(
                                                          width: 32,
                                                          height: 32,
                                                          child: Center(
                                                            child: Text(
                                                              leg
                                                                      .route
                                                                      ?.shortName ??
                                                                  '??',
                                                              style: TextStyle(
                                                                color:
                                                                    leg
                                                                        .route
                                                                        ?.textColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                leg.transitLeg
                                                    ? leg.headsign ??
                                                        leg.route?.longName ??
                                                        'Unknown'
                                                    : '${displayDistance(leg.distance)} - ${displayTime(leg.duration)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (leg.transitLeg)
                                          Text(
                                            '${displayDistance(leg.distance)} - ${displayTime(leg.duration)}${leg.intermediateStops != null ? ' - ${leg.intermediateStops!.length} stops' : ''}',
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Destination
                          final place = legs.last.to;
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 18.0,
                              top: 4.0,
                              bottom: 4.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Destination",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  place.name,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  formatTime(place.arrival?.scheduledTime) ??
                                      '',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
