import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/colors.dart';
import 'package:otpand/widgets/route_icon.dart';

class LegDepartureWidget extends StatelessWidget {
  final Leg leg;
  final bool isCurrent;
  final bool? isSlower;

  const LegDepartureWidget({
    super.key,
    required this.leg,
    this.isCurrent = false,
    this.isSlower,
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
        if (isSlower == true) SizedBox(width: 4),
        if (isSlower == true)
          Icon(
            Icons.slow_motion_video,
            size: 16,
            color: Colors.orange,
          ),
        if (leg.transferRisk != null) const SizedBox(width: 6),
        if (leg.transferRisk != null)
          _ReliabilityDot(reliability: leg.transferRisk!.reliability),
      ],
    );
  }
}

class _ReliabilityDot extends StatelessWidget {
  final double reliability;

  const _ReliabilityDot({required this.reliability});

  @override
  Widget build(BuildContext context) {
    final pct = (reliability * 100).round();
    return Tooltip(
      message: '$pct %',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: transferReliabilityFg(reliability),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
