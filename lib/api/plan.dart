import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/extractor.dart';

/// Returns a map: { "plans": List<Plan>, "pageInfo": Map }
Future<Map<String, dynamic>> submitQuery({
  required Location fromLocation,
  required Location toLocation,
  required String selectedMode,
  required String timeType,
  required DateTime? selectedDateTime,
  String? after,
  String? before,
  int? first,
  int? last,
}) async {
  double fromLat = fromLocation.lat;
  double fromLon = fromLocation.lon;
  double toLat = toLocation.lat;
  double toLon = toLocation.lon;

  print('($fromLat, $fromLon), ($toLat, $toLon)');

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

  // Build variables map
  Map<String, dynamic> variables = {
    "origin": {
      "location": {
        "coordinate": {"latitude": fromLat, "longitude": fromLon},
      },
      "label": fromLocation.name,
    },
    "destination": {
      "location": {
        "coordinate": {"latitude": toLat, "longitude": toLon},
      },
      "label": toLocation.name,
    },
    "dateTime": {directionType: dtIso},
  };
  if (after != null) variables["after"] = after;
  if (before != null) variables["before"] = before;
  if (first != null) variables["first"] = first;
  if (last != null) variables["last"] = last;

  // Build modes part for variables
  switch (selectedMode) {
    case "WALK":
      variables["modes"] = {
        "direct": ["WALK"],
      };
      break;
    case "BIKE":
      variables["modes"] = {
        "direct": ["BICYCLE"],
      };
      break;
    case "CAR":
      variables["modes"] = {
        "direct": ["CAR"],
      };
      break;
    case "TRANSIT":
      variables["modes"] = {
        "direct": ["WALK"],
        "transit": {
          "transit": [
            {"mode": "BUS"},
            {"mode": "RAIL"},
            {"mode": "SUBWAY"},
            {"mode": "TRAM"},
            {"mode": "FERRY"},
          ],
        },
      };
      break;
  }

  String gql = '''
    query PlanConnection(
      \$origin: PlanLabeledLocationInput!
      \$destination: PlanLabeledLocationInput!
      \$dateTime: PlanDateTimeInput
      \$after: String
      \$before: String
      \$first: Int
      \$last: Int
      \$modes: PlanModesInput
    ) {
      planConnection(
        origin: \$origin
        destination: \$destination
        dateTime: \$dateTime
        after: \$after
        before: \$before
        first: \$first
        last: \$last
        modes: \$modes
      ) {
        edges {
          cursor
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
                gtfsId
              }
              duration
              distance
							intermediatePlaces {
								stop {
									name
									gtfsId
								}
								arrival {
									scheduledTime
									estimated {
										time
										delay
									}
								}
								departure {
									scheduledTime
									estimated {
										time
										delay
									}
								}
							}
              interlineWithPreviousLeg
            }

          }
        }
        pageInfo {
          endCursor
          hasNextPage
          hasPreviousPage
          searchWindowUsed
          startCursor
        }
      }
    }

  ''';

  final resp = await http.post(
    Uri.parse('https://maps.bhasher.com/otp/gtfs/v1'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': gql, 'variables': variables}),
  );
  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    if (data['data'] != null &&
        data['data']['planConnection'] != null &&
        data['data']['planConnection']['edges'] != null) {
      final List edges = data['data']['planConnection']['edges'];
      final pageInfo = data['data']['planConnection']['pageInfo'];
      final List plans =
          edges
              .map(
                (e) => {
                  'start': e['node']['start'],
                  'end': e['node']['end'],
                  'legs': e['node']['legs'],
                },
              )
              .toList();
      return {"plans": await parsePlans(plans), "pageInfo": pageInfo};
    } else {
      throw Exception("No plan found. Check your input.");
    }
  } else {
    throw Exception("Error from backend: ${resp.statusCode}");
  }
}
