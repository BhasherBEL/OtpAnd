import 'package:flutter/material.dart';
import 'package:otpand/objects/timedStop.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/colors.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:otpand/widgets/intermediateStops.dart';

class RoutePage extends StatelessWidget {
  final Plan plan;

  const RoutePage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final legs = plan.legs;

    return Scaffold(
      backgroundColor: primary50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: primary500),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Journey Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                offset: Offset(0, 4),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.hardEdge,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          legs.first.from.name,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_right_alt,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              legs.last.to.name,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatTime(
                                              legs
                                                  .first
                                                  .from
                                                  .departure
                                                  ?.scheduledTime,
                                            ) ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatTime(
                                              legs
                                                  .last
                                                  .to
                                                  .arrival
                                                  ?.scheduledTime,
                                            ) ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
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
                    itemCount: legs.length + 1,
                    contentsBuilder: (context, index) {
                      if (index < legs.length) {
                        final leg = legs[index];
                        final previousLeg = index > 0 ? legs[index - 1] : null;

                        final departureTimeRt =
                            leg.from.departure?.estimated?.time;
                        final departureTimeTheory =
                            leg.from.departure?.scheduledTime;
                        final departureTime =
                            departureTimeRt ?? departureTimeTheory;
                        final departureDelayed =
                            departureTimeRt != null &&
                            departureTimeRt != departureTimeTheory;

                        final arrivalTimeRt =
                            previousLeg?.to.arrival?.estimated?.time;
                        final arrivalTimeTheory =
                            previousLeg?.to.arrival?.scheduledTime;
                        final arrivalTime = arrivalTimeRt ?? arrivalTimeTheory;
                        final arrivalDelayed =
                            arrivalTimeRt != null &&
                            arrivalTimeRt != arrivalTimeTheory;

                        final transferTime =
                            arrivalTime != null
                                ? parseTime(
                                  departureTime,
                                )?.difference(parseTime(arrivalTime)!).inSeconds
                                : null;
                        final hasTransfer =
                            transferTime != null && transferTime > 0;

                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 18.0,
                            bottom: 4.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      leg.from.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                    children: [
                                      if (hasTransfer ||
                                          previousLeg != null &&
                                              previousLeg.transitLeg)
                                        Row(
                                          children: [
                                            if (arrivalDelayed)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 4,
                                                ),
                                                child: Text(
                                                  formatTime(arrivalTimeRt)!,
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              formatTime(arrivalTimeTheory) ??
                                                  '??:??',
                                              style: TextStyle(
                                                color:
                                                    arrivalTimeRt == null
                                                        ? Colors.grey.shade700
                                                        : Colors.green,
                                                decoration:
                                                    arrivalDelayed
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (hasTransfer)
                                        Icon(Icons.arrow_downward, size: 12),
                                      if (hasTransfer ||
                                          leg.transitLeg ||
                                          previousLeg == null)
                                        Row(
                                          children: [
                                            if (departureDelayed)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 4,
                                                ),
                                                child: Text(
                                                  formatTime(departureTimeRt)!,
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              formatTime(departureTimeTheory) ??
                                                  '??:??',
                                              style: TextStyle(
                                                color:
                                                    departureTimeRt == null
                                                        ? Colors.grey.shade700
                                                        : Colors.green,
                                                decoration:
                                                    departureDelayed
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              Padding(
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
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
                                                color: colorForMode(leg.mode),
                                              ),
                                              if (leg.route?.shortName !=
                                                  null) ...[
                                                const SizedBox(width: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: ColoredBox(
                                                    color:
                                                        leg.route?.color ??
                                                        colorForMode(leg.mode),
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
                                      IntermediateStopsWidget(
                                        stops: leg.intermediateStops!,
                                        leg: leg,
                                      ),
                                  ],
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
                                formatTime(place.arrival?.scheduledTime) ?? '',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
