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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.directions, color: Colors.blue),
        title: Text('$departure → $arrival'),
        subtitle: Text('Duration: $duration'),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}
