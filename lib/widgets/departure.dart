import 'package:flutter/material.dart';
import 'package:otpand/objects/timed_stop.dart';
import 'package:otpand/pages/trip.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/route_colors.dart';
import 'package:otpand/widgets/route_icon.dart';

class DepartureWidget extends StatelessWidget {
  final TimedStop timedStop;

  const DepartureWidget({super.key, required this.timedStop});

  @override
  Widget build(BuildContext context) {
    final route = timedStop.trip?.route;
    final trip = timedStop.trip;
    final dep = timedStop.departure;
    final scheduledTime = dep.scheduledTime;
    final estimatedTime = dep.estimated?.time;

    // Get route name for background color
    final routeName = timedStop.pattern?.route.shortName ??
        timedStop.trip?.route?.shortName ??
        'Unknown';
    final backgroundColor = getRouteBackgroundColor(routeName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (route != null) RouteIconWidget(route: route),
                if (route != null) const SizedBox(width: 12),
                Expanded(child: Container()),
                Builder(
                  builder: (context) {
                    if (estimatedTime != null) {
                      if (estimatedTime != scheduledTime) {
                        return Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                formatTime(estimatedTime)!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            Text(
                              formatTime(scheduledTime) ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Text(
                          formatTime(scheduledTime) ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        );
                      }
                    } else {
                      return Text(
                        formatTime(scheduledTime) ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              timedStop.headSign ??
                  timedStop.trip?.headsign ??
                  timedStop.trip?.route?.longName ??
                  'Unknown',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: trip != null && timedStop.serviceDate != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => TripPage(
                            trip: trip,
                            serviceDate: timedStop.serviceDate!,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text(
                [
                  if (route?.shortName != null) route!.shortName,
                  if (trip?.shortName != null) trip!.shortName,
                ].where((s) => s != null && s.isNotEmpty).join('•'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
