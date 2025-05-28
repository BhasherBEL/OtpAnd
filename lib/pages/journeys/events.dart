import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otpand/pages/journeys/event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventsWidget extends StatefulWidget {
  const EventsWidget({super.key});

  @override
  State<EventsWidget> createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  List<Event> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final useCalendars = (await SharedPreferences.getInstance()).getBool(
      'otp_use_calendars_location',
    );

    if (useCalendars == null || !useCalendars) {
      setState(() {
        _events = [];
        _loading = false;
      });
      return;
    }

    final calendarPlugin = DeviceCalendarPlugin();

    var permissionsGranted = await calendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess &&
        (permissionsGranted.data == null || permissionsGranted.data == false)) {
      permissionsGranted = await calendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess ||
          permissionsGranted.data == null ||
          permissionsGranted.data == false) {
        setState(() {
          _events = [];
          _loading = false;
        });
        return;
      }
    }

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 7));
    final endOfTomorrow = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      23,
      59,
      59,
    );

    final List<Event> events = [];

    final calendars = (await calendarPlugin.retrieveCalendars()).data;

    if (calendars == null) {
      setState(() {
        _events = [];
        _loading = false;
      });
      return;
    }

    for (final calendar in calendars) {
      final calendarEvents = await calendarPlugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: now, endDate: endOfTomorrow),
      );
      if (calendarEvents.data == null) continue;
      events.addAll(
        calendarEvents.data!.where(
          (e) =>
              e.start != null &&
              e.location != null &&
              e.location!.trim().isNotEmpty,
        ),
      );
    }

    setState(() {
      _events = events.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_events.isEmpty) {
      return SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upcoming events",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = _events[index];
              return EventWidget(event: event);
            },
          ),
        ],
      ),
    );
  }
}
