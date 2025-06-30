import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/utils.dart';

class SmallRoute extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  const SmallRoute({super.key, required this.plan, this.onTap});

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
    final duration = displayTime(
      calculateDurationFromString(
        filteredLegs.first.from.departure?.scheduledTime,
        filteredLegs.last.to.arrival?.scheduledTime,
      ),
    );

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
                  Text(
                    '$departure - $arrival',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    duration,
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
                    children: [
                      for (int i = 0; i < filteredLegs.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: widths[i],
                            child: _LegTile(leg: filteredLegs[i]),
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
    final bgColor = leg.color ?? Colors.grey.shade300;

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
