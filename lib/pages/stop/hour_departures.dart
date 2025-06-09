import 'package:flutter/material.dart';
import 'package:otpand/objects/timed_stop.dart';
import 'package:otpand/pages/trip.dart';
import 'package:otpand/utils/route_colors.dart';

class HourDeparturesWidget extends StatelessWidget {
  final List<TimedStop> timedStops;
  final int hour;

  const HourDeparturesWidget({
    required this.timedStops,
    required this.hour,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = hour == DateTime.now().hour;
    final sortedTimedStops =
        timedStops..sort(
          (a, b) => a.departure.scheduledDateTime!.compareTo(
            b.departure.scheduledDateTime!,
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isCurrent
                ? Theme.of(context).primaryColor.withOpacity(0.25)
                : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hour.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final minWidth = 60.0;
                final spacing = 2.0;

                final maxItemsPerRow = (availableWidth / (minWidth + spacing))
                    .floor()
                    .clamp(1, 20);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: maxItemsPerRow,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: sortedTimedStops.length,
                  itemBuilder: (context, index) {
                    final timedStop = sortedTimedStops[index];
                    final routeName =
                        timedStop.pattern?.route.shortName ??
                        timedStop.trip?.route?.shortName ??
                        'Unknown';
                    final backgroundColor =
                        timedStop.pattern?.route.color ??
                        getRouteBackgroundColor(routeName);
                    final textColor =
                        timedStop.pattern?.route.textColor ?? Colors.black;

                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap:
                              timedStop.trip != null &&
                                      timedStop.serviceDate != null
                                  ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (context) => TripPage(
                                              trip: timedStop.trip!,
                                              serviceDate:
                                                  timedStop.serviceDate!,
                                            ),
                                      ),
                                    );
                                  }
                                  : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                timedStop.departure.scheduledDateTime!.minute
                                    .toString()
                                    .padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '/',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (timedStop.pattern != null)
                                    Text(
                                      timedStop.pattern!.route.shortName,
                                      style: TextStyle(
                                        fontSize:
                                            (timedStop.trip == null ||
                                                    timedStop.trip!.shortName ==
                                                        null)
                                                ? 12
                                                : 8,
                                        color: textColor.withOpacity(0.5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (timedStop.trip != null &&
                                      timedStop.trip!.shortName != null)
                                    Text(
                                      timedStop.trip!.shortName!,
                                      style: TextStyle(
                                        fontSize: 6,
                                        color: textColor.withOpacity(0.5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
