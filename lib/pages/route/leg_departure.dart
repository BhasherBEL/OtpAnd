import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/widgets/route_icon.dart';

class LegDepartureWidget extends StatelessWidget {
  final Leg leg;
  final bool isCurrent;

  const LegDepartureWidget({
    super.key,
    required this.leg,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leg.route != null) RouteIconWidget(route: leg.route!, size: 8),
        Expanded(
          child: Text(
              leg.headsign ??
                  leg.trip?.headsign ??
                  leg.trip?.route?.longName ??
                  leg.to.name,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              )),
        ),
        Builder(
          builder: (context) {
            final estimatedFromTime = leg.from.departure?.estimated?.time;
            final scheduledFromTime = leg.from.departure?.scheduledTime;

            if (estimatedFromTime != null) {
              if (estimatedFromTime != scheduledFromTime) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        formatTime(estimatedFromTime)!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      formatTime(scheduledFromTime) ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        decoration: TextDecoration.lineThrough,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              } else {
                return Text(
                  formatTime(scheduledFromTime) ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }
            } else {
              return Text(
                formatTime(scheduledFromTime) ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }
          },
        ),
        const Text(' → '),
        Builder(
          builder: (context) {
            final estimatedToTime = leg.to.arrival?.estimated?.time;
            final scheduledToTime = leg.to.arrival?.scheduledTime;

            if (estimatedToTime != null) {
              if (estimatedToTime != scheduledToTime) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        formatTime(estimatedToTime)!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      formatTime(scheduledToTime) ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        decoration: TextDecoration.lineThrough,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              } else {
                return Text(
                  formatTime(scheduledToTime) ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }
            } else {
              return Text(
                formatTime(scheduledToTime) ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
