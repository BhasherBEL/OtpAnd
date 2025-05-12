import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:otpAnd/utils.dart';
import 'package:timelines_plus/timelines_plus.dart';

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
              "modes: { direct: [WALK FLEX], transit: { transit: [{ mode: BUS }, { mode: RAIL }, { mode: SUBWAY }, { mode: TRAM }, { mode: FERRY }] } }";
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
								headsign
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
									color
									textColor
                },
                duration
                distance
								intermediateStops {
                  name
                  parentStation {
										name
                    id
                  }
                  platformCode
                  id
                }
								interlineWithPreviousLeg
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
    final dt = DateTime.parse(iso).toLocal();
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
            FixedTimeline.tileBuilder(
              theme: TimelineThemeData(
                nodePosition: 0,
                color: Colors.blueAccent,
                indicatorTheme: IndicatorThemeData(size: 26, position: 0),
                connectorTheme: ConnectorThemeData(
                  thickness: 2.0,
                  color: Colors.blueAccent,
                ),
              ),
              builder: TimelineTileBuilder.connected(
                connectionDirection: ConnectionDirection.before,
                itemCount: legs.length + 1,
                contentsBuilder: (context, index) {
                  if (index < legs.length) {
                    // Leg info
                    final leg = legs[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 18.0, bottom: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(leg.from.name),
                              Text(
                                formatTime(leg.from.departure?.scheduledTime) ??
                                    '??:??',
                              ),
                            ],
                          ),
                          Card(
                            color: Colors.grey.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              iconForMode(leg.mode),
                                              color: colorForMode(leg.mode),
                                            ),
                                            if (leg.route?.shortName !=
                                                null) ...[
                                              const SizedBox(width: 6),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: ColoredBox(
                                                  color:
                                                      leg.route?.color ??
                                                      colorForMode(leg.mode),
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: Center(
                                                      child: Text(
                                                        leg.route?.shortName ??
                                                            '??',
                                                        style: TextStyle(
                                                          color:
                                                              leg
                                                                  .route
                                                                  ?.textColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          leg.headsign,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${displayDistance(leg.distance)} - ${displayTime(leg.duration)}${leg.intermediateStops != null ? ' - ${leg.intermediateStops!.length} stops' : ''}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Destination
                    final place = legs.last.to;
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 18.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Destination",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            place.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            formatTime(place.arrival?.scheduledTime) ?? '',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                },
                indicatorBuilder: (context, index) {
                  if (index == 0) {
                    return const DotIndicator(
                      size: 24,
                      color: Colors.green,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.white,
                        size: 16,
                      ),
                    );
                  } else if (index == legs.length) {
                    return const DotIndicator(
                      size: 24,
                      color: Colors.red,
                      child: Icon(Icons.flag, color: Colors.white, size: 16),
                    );
                  } else {
                    return const OutlinedDotIndicator(
                      size: 20,
                      color: Colors.blue,
                      backgroundColor: Colors.white,
                      borderWidth: 2.0,
                    );
                  }
                },
                connectorBuilder: (context, index, type) {
                  if (index == 0) {
                    return null;
                  }
                  return const SolidLineConnector();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
