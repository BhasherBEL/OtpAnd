import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/objs.dart';
import 'package:otpand/extractor.dart';

Future<Map<String, dynamic>> submitQuery({
  required Location fromLocation,
  required Location toLocation,
  required Profile profile,
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

  String directionType =
      (timeType == "arrive") ? "latestArrival" : "earliestDeparture";

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
    "modes": profile.getPlanModes(),
    "preferences": profile.getPlanPreferences(),
  };
  if (after != null) variables["after"] = after;
  if (before != null) variables["before"] = before;
  if (first != null) variables["first"] = first;
  if (last != null) variables["last"] = last;

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
			\$preferences: PlanPreferencesInput
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
				preferences: \$preferences
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
							realTime
							serviceDate
              from {
                name
                lat
                lon
								stop {
									gtfsId
								}
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
								stop {
									gtfsId
								}
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
							trip {
								gtfsId
								tripHeadsign
								tripShortName
								stoptimes {
									stop {
										gtfsId
									}
									scheduledArrival
									realtimeArrival
									scheduledDeparture
									realtimeDeparture
									realtime
									dropoffType
									pickupType
								}
							}
              duration
              distance
              interlineWithPreviousLeg
							previousLegs(numberOfLegs: 1) {
								from {
									departure {
										estimated {
											time
											delay
										}
										scheduledTime
									}
								}
							}
							nextLegs(numberOfLegs: 2) {
								from {
									departure {
										estimated {
											time
											delay
										}
										scheduledTime
									}
								}
							}
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
  print(resp.body);
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

Future<Leg?> fetchLegById(String legId) async {
  final String gql = '''
    query LegById(\$id: String!) {
      leg(id: \$id) {
        id
        mode
        headsign
        transitLeg
				realTime
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
				trip {
					gtfsId
					tripHeadsign
					tripShortName
					stoptimes {
						stop {
							gtfsId
						}
						scheduledArrival
						realtimeArrival
						scheduledDeparture
						realtimeDeparture
						realtime
						dropoffType
						pickupType
					}
				}
        interlineWithPreviousLeg
				previousLegs(numberOfLegs: 1) {
					from {
						departure {
							estimated {
								time
								delay
							}
							scheduledTime
						}
					}
				}
				nextLegs(numberOfLegs: 2) {
					from {
						departure {
							estimated {
								time
								delay
							}
							scheduledTime
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
    body: jsonEncode({
      'query': gql,
      'variables': {'id': legId},
    }),
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    if (data['data'] != null && data['data']['leg'] != null) {
      // Use your existing Leg parsing logic from extractor.dart
      return parseLeg(data['data']['leg']);
    } else {
      return null;
    }
  } else {
    return null;
  }
}
