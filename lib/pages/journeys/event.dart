import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otpand/objects/history.dart';
import 'package:otpand/utils/gnss.dart';
import 'package:otpand/widgets/datetime_picker.dart';
import 'package:otpand/objects/location.dart' as loc_obj;

class EventWidget extends StatelessWidget {
  const EventWidget({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        event.start != null
            ? DateFormat('EEE, MMM d • HH:mm').format(event.start!)
            : '';
    final title = event.title ?? 'Untitled event';
    return ListTile(
      leading: const Icon(Icons.event, color: Colors.deepOrange),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      titleAlignment: ListTileTitleAlignment.center,
      subtitle: Text(
        "$dateStr\n${event.location?.replaceAll('\n', ' ') ?? ''}",
      ),
      isThreeLine: true,
      onTap: () async {
        if (event.location == null) return;
        final loc = await resolveAddress(event.location!, context: context);
        if (loc == null) return;

        History.update(
          toLocation: loc_obj.Location(
            name: title,
            displayName: title,
            lat: loc.$1,
            lon: loc.$2,
          ),
          dateTime: DateTimePickerValue(
            mode: DateTimePickerMode.arrival,
            dateTime: event.start,
          ),
        );
      },
    );
  }
}
