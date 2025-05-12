import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'objs.dart';
import 'extractor.dart';

void main() {
  runApp(OTPApp());
}

class OTPApp extends StatelessWidget {
  const OTPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTPAnd',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OTPHomePage(),
    );
  }
}

class OTPHomePage extends StatefulWidget {
  const OTPHomePage({super.key});

  @override
  State<OTPHomePage> createState() => _OTPHomePageState();
}

class _OTPHomePageState extends State<OTPHomePage> {
  final TextEditingController fromLatCtrl = TextEditingController(
    text: '50.803449',
  );
  final TextEditingController fromLonCtrl = TextEditingController(
    text: '4.405465',
  );
  final TextEditingController toLatCtrl = TextEditingController(
    text: '50.89820',
  );
  final TextEditingController toLonCtrl = TextEditingController(
    text: '4.34035',
  );

  String selectedMode = 'WALK';
  String timeType = 'now'; // now, start, arrive
  DateTime? selectedDateTime;

  bool isLoading = false;
  List<Plan> results = [];
  String? errorMsg;

  List<String> mainModes = ['WALK', 'TRANSIT', 'BIKE', 'CAR'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OTPAnd")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: fromLatCtrl,
                    decoration: InputDecoration(labelText: "From latitude"),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    controller: fromLonCtrl,
                    decoration: InputDecoration(labelText: "From longitude"),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: toLatCtrl,
                    decoration: InputDecoration(labelText: "To latitude"),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    controller: toLonCtrl,
                    decoration: InputDecoration(labelText: "To longitude"),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text("Mode: "),
                for (var mode in mainModes)
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(mode),
                      selected: selectedMode == mode,
                      onSelected: (_) {
                        setState(() {
                          selectedMode = mode;
                        });
                      },
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Time: "),
                ChoiceChip(
                  label: Text("Now"),
                  selected: timeType == "now",
                  onSelected: (_) {
                    setState(() {
                      timeType = "now";
                      selectedDateTime = null;
                    });
                  },
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text("Starting at"),
                  selected: timeType == "start",
                  onSelected: (_) async {
                    final dt = await pickDateTime(context);
                    if (dt != null) {
                      setState(() {
                        timeType = "start";
                        selectedDateTime = dt;
                      });
                    }
                  },
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text("Arriving at"),
                  selected: timeType == "arrive",
                  onSelected: (_) async {
                    final dt = await pickDateTime(context);
                    if (dt != null) {
                      setState(() {
                        timeType = "arrive";
                        selectedDateTime = dt;
                      });
                    }
                  },
                ),
                if (selectedDateTime != null)
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : submitQuery,
              child:
                  isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Submit"),
            ),
            SizedBox(height: 24),
            if (errorMsg != null)
              Text(errorMsg!, style: TextStyle(color: Colors.red)),
            if (results.isNotEmpty)
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (ctx, idx) {
                  final plan = results[idx];
                  return PlanWidget(plan: plan);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> submitQuery() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      results.clear();
    });

    try {
      double fromLat = double.parse(fromLatCtrl.text.trim());
      double fromLon = double.parse(fromLonCtrl.text.trim());
      double toLat = double.parse(toLatCtrl.text.trim());
      double toLon = double.parse(toLonCtrl.text.trim());

      String dtIso;
      String localTZ =
          DateTime.now().timeZoneOffset.isNegative
              ? '-${DateTime.now().timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00'
              : '+${DateTime.now().timeZoneOffset.inHours.toString().padLeft(2, '0')}:00';

      if (timeType == "now" || selectedDateTime == null) {
        dtIso = DateFormat("yyyy-MM-ddTHH:mm").format(DateTime.now()) + localTZ;
      } else {
        dtIso =
            DateFormat("yyyy-MM-ddTHH:mm").format(selectedDateTime!) + localTZ;
      }

      // build modes part
      String modesStr = "";
      switch (selectedMode) {
        case "WALK":
          modesStr = "modes: { direct: [WALK]}";
          break;
        case "BIKE":
          modesStr = "modes: { direct: [BICYCLE]}";
          break;
        case "CAR":
          modesStr = "modes: { direct: [CAR]}";
          break;
        case "TRANSIT":
          modesStr =
              "modes: { direct: [WALK], transit: { transit: [{ mode: BUS }, { mode: RAIL }, { mode: SUBWAY }, { mode: TRAM }, { mode: FERRY }] } }";
          break;
      }

      // construct GraphQL
      String directionType =
          (timeType == "arrive") ? "latestArrival" : "earliestDeparture";
      String gql = '''
      {
        planConnection(
          origin: { location: { coordinate: { latitude: $fromLat, longitude: $fromLon } } }
          destination: { location: { coordinate: { latitude: $toLat, longitude: $toLon } } }
          dateTime: { $directionType: "$dtIso" }
          $modesStr
        ) {
          edges {
            node {
              start
              end
              legs {
                mode
                from {
                  name
                  lat
                  lon
                  departure {
                    scheduledTime
                    estimated {
                      time
                      delay
                    }
                  }
                }
                to {
                  name
                  lat
                  lon
                  arrival {
                    scheduledTime
                    estimated {
                      time
                      delay
                    }
                  }
                }
                route {
                  gtfsId
                  longName
                  shortName
                }
                legGeometry {
                  points
                }
              }
            }
          }
        }
      }
      ''';

      final resp = await http.post(
        Uri.parse('https://maps.bhasher.com/otp/gtfs/v1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': gql}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['data'] != null &&
            data['data']['planConnection'] != null &&
            data['data']['planConnection']['edges'] != null) {
          final List plans = data['data']['planConnection']['edges'];
          setState(() {
            results = parsePlans(
              plans
                  .map(
                    (e) => {
                      'start': e['node']['start'],
                      'end': e['node']['end'],
                      'legs': e['node']['legs'],
                    },
                  )
                  .toList(),
            );
            isLoading = false;
          });
        } else {
          setState(() {
            errorMsg = "No plan found. Check your input.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = "Error from backend: ${resp.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Error: $e";
        isLoading = false;
      });
    }
  }
}

// Add icons for each mode
IconData iconForMode(String mode) {
  switch (mode) {
    case "WALK":
      return Icons.directions_walk;
    case "BICYCLE":
      return Icons.directions_bike;
    case "CAR":
      return Icons.directions_car;
    case "BUS":
      return Icons.directions_bus;
    case "RAIL":
    case "SUBWAY":
      return Icons.train;
    case "TRAM":
      return Icons.tram;
    case "FERRY":
      return Icons.directions_boat;
    default:
      return Icons.trip_origin;
  }
}

Color colorForMode(String mode) {
  switch (mode) {
    case "WALK":
      return Colors.green;
    case "BUS":
      return Colors.blue;
    case "SUBWAY":
      return Colors.deepOrange;
    case "TRAM":
      return Colors.purple;
    case "RAIL":
      return Colors.teal;
    default:
      return Colors.grey.shade400;
  }
}

String? formatTime(String? iso) {
  if (iso == null) return null;
  try {
    final dt = DateTime.parse(iso);
    return DateFormat('HH:mm').format(dt);
  } catch (_) {
    return iso;
  }
}

String legDescription(Leg leg) {
  if (leg.mode == "WALK") {
    return "Walk";
  } else if (leg.mode == "BICYCLE") {
    return "Bike";
  } else if (leg.mode == "CAR") {
    return "Car";
  } else if (leg.mode == "BUS" ||
      leg.mode == "RAIL" ||
      leg.mode == "SUBWAY" ||
      leg.mode == "TRAM" ||
      leg.mode == "FERRY") {
    String route =
        leg.route?.shortName != null ? " ${leg.route!.shortName}" : "";
    return "${capitalize(leg.mode)}$route";
  } else if (leg.route != null) {
    String route =
        leg.route!.shortName != null ? " ${leg.route!.shortName}" : "";
    return "${capitalize(leg.mode)}$route";
  }
  return capitalize(leg.mode);
}

String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;

class PlanWidget extends StatelessWidget {
  const PlanWidget({super.key, required this.plan});
  final Plan plan;

  String _placeLabel(int idx, int total) {
    if (idx == 0) return "Origin";
    if (idx == total - 1) return "Destination";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final legs = plan.legs;
    final places = <Place>[];
    // Build ordered list of places: origin, all stops, destination
    places.add(legs.first.from);
    for (final leg in legs) {
      places.add(leg.to);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // TITLE BAR
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                Text(
                  places.first.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "${formatTime(places.first.departure?.scheduledTime) ?? ''} → "
                  "${formatTime(places.last.arrival?.scheduledTime) ?? ''}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 18), // spacer
            // TIMELINE: alternate place tile, leg info, place tile, ...
            ...[
              for (final leg in legs) ...[TimelineItem(leg: leg)],
            ],
          ],
        ),
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final Leg leg;
  final bool first;
  final bool last;

  const TimelineItem({
    super.key,
    required this.leg,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.17,
          isFirst: first,
          isLast: last,
          indicatorStyle: IndicatorStyle(
            width: 26,
            color:
                first
                    ? Colors.green
                    : last
                    ? Colors.red
                    : Colors.blue,
            iconStyle: IconStyle(
              iconData:
                  first
                      ? Icons.circle
                      : last
                      ? Icons.flag
                      : Icons.location_on,
              color: Colors.white,
            ),
          ),
          beforeLineStyle: const LineStyle(
            thickness: 2,
            color: Colors.blueAccent,
          ),
          afterLineStyle: const LineStyle(
            thickness: 2,
            color: Colors.blueAccent,
          ),
          startChild: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              formatTime(
                    first
                        ? leg.from.departure?.scheduledTime
                        : leg.to.arrival?.scheduledTime,
                  ) ??
                  '??:??',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          endChild: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 18.0,
              top: 4.0,
              bottom: 4.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  first
                      ? "Origin"
                      : last
                      ? "Destination"
                      : leg.from.name,
                  style: TextStyle(
                    fontWeight:
                        first || last ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (!last)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        iconForMode(leg.mode),
                        color: colorForMode(leg.mode),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        legDescription(leg),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorForMode(leg.mode),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
