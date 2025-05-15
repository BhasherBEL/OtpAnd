import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/extractor.dart';

Future<List<Plan>> submitQuery({
  required Location fromLocation,
  required Location toLocation,
  required String selectedMode,
  required String timeType,
  required DateTime? selectedDateTime,
}) async {
  double fromLat = fromLocation.lat;
  double fromLon = fromLocation.lon;
  double toLat = toLocation.lat;
  double toLon = toLocation.lon;

  String dtIso;
  String localTZ =
      DateTime.now().timeZoneOffset.isNegative
          ? '-${DateTime.now().timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00'
          : '+${DateTime.now().timeZoneOffset.inHours.toString().padLeft(2, '0')}:00';

  if (timeType == "now" || selectedDateTime == null) {
    dtIso = DateFormat("yyyy-MM-ddTHH:mm").format(DateTime.now()) + localTZ;
  } else {
    dtIso = DateFormat("yyyy-MM-ddTHH:mm").format(selectedDateTime) + localTZ;
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
						id
            mode
            headsign
            transitLeg
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
              id
            },
            duration
            distance
            intermediateStops {
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
      return parsePlans(
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
    } else {
      throw Exception("No plan found. Check your input.");
    }
  } else {
    throw Exception("Error from backend: ${resp.statusCode}");
  }
}
