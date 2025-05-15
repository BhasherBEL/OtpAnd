import 'package:flutter/material.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/utils.dart';

class SmallRoute extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  const SmallRoute({super.key, required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final legs = plan.legs;
    final departure =
        formatTime(legs.first.from.departure?.scheduledTime) ?? '--:--';
    final arrival = formatTime(legs.last.to.arrival?.scheduledTime) ?? '--:--';
    final duration = displayTime(
      calculateDurationFromString(
        legs.first.from.departure?.scheduledTime,
        legs.last.to.arrival?.scheduledTime,
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
                  final minWidths =
                      legs.map((leg) {
                        if (leg.mode == "WALK") {
                          return 36.0 +
                              (leg.distance.round().toString().length * 8);
                        } else {
                          return 48.0 +
                              ((leg.route?.shortName ?? '').length * 10);
                        }
                      }).toList();

                  final totalMinWidth = minWidths.fold<double>(
                    0,
                    (a, b) => a + b,
                  );

                  final availableWidth = constraints.maxWidth;

                  final totalHorizontalPadding = 2.0 * 2 * legs.length;
                  final adjustedAvailableWidth = (availableWidth -
                          totalHorizontalPadding)
                      .clamp(0.0, double.infinity);
                  final extraWidth =
                      (adjustedAvailableWidth > totalMinWidth)
                          ? adjustedAvailableWidth - totalMinWidth
                          : 0.0;

                  final totalDuration = legs.fold<num>(
                    0,
                    (sum, leg) => sum + leg.duration,
                  );

                  final widths = <double>[];
                  for (int i = 0; i < legs.length; i++) {
                    final proportion =
                        (legs[i].duration / totalDuration).toDouble();
                    final addWidth = extraWidth * proportion;
                    widths.add(minWidths[i] + addWidth);
                  }

                  final row = Row(
                    children: [
                      for (int i = 0; i < legs.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: widths[i],
                            child: _LegTile(leg: legs[i]),
                          ),
                        ),
                    ],
                  );

                  // Always wrap in SingleChildScrollView to prevent overflow
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
    final bgColor = _legColor(leg);
    final textColor =
        leg.route?.textColor ??
        (ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
            ? Colors.white
            : Colors.black);

    Widget? leading;
    Widget label;
    if (leg.mode == "WALK") {
      leading = const Icon(Icons.directions_walk, size: 18);
      label = Text(
        displayDistanceInTime(leg.distance),
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      );
    } else {
      leading = Icon(
        leg.mode == "BUS" ? Icons.directions_bus : Icons.train,
        size: 18,
        color: textColor,
      );
      label = Text(
        leg.route?.shortName ?? '',
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [leading, const SizedBox(width: 4), label],
      ),
    );
  }
}

Color _legColor(Leg leg) {
  if (leg.mode == "WALK") return Colors.grey.shade300;
  if (leg.mode == "BUS") return Colors.amber.shade600;
  if (leg.mode == "RAIL" || leg.mode == "TRAIN")
    return Colors.lightBlue.shade300;
  return Colors.grey.shade400;
}
