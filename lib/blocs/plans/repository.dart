import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:otpand/blocs/plans/helpers.dart';
import 'package:otpand/objects/config.dart';
import 'package:http/http.dart' as http;
import 'package:otpand/objects/plan.dart';

const String legFieldsFragment = '''
		fragment LegFields on Leg {
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
			}
			duration
			distance
			interlineWithPreviousLeg
		}
''';

class PlansRepository {
  Future<Map<String, dynamic>> fetchPlans(PlansQueryVariables variables) async {
    String gql = '''
		$legFieldsFragment

		query PlanConnection(\$origin: PlanLabeledLocationInput!, \$destination: PlanLabeledLocationInput!, \$dateTime: PlanDateTimeInput, \$searchWindow: Duration, \$after: String, \$before: String, \$first: Int, \$last: Int, \$modes: PlanModesInput, \$preferences: PlanPreferencesInput) {
			planConnection(
				origin: \$origin
				destination: \$destination
				dateTime: \$dateTime
				searchWindow: \$searchWindow
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
							...LegFields
							legGeometry {
								points
							}
							trip {
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
							previousLegs(
								numberOfLegs: 1
								destinationModesWithParentStation: [BUS, RAIL, SUBWAY, TRAM, FERRY]
								originModesWithParentStation: [BUS, RAIL, SUBWAY, TRAM, FERRY]
							) {
								...LegFields
							}
							nextLegs(numberOfLegs: 2) {
								...LegFields
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
      Uri.parse('${Config().otpUrl}/otp/gtfs/v1'),
      headers: {'Content-Type': 'application/json', 'Content-Encoding': 'gzip'},
      body: jsonEncode({'query': gql, 'variables': variables.get()}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['data'] != null &&
          data['data']['planConnection'] != null &&
          data['data']['planConnection']['edges'] != null) {
        final List<dynamic> edges =
            data['data']['planConnection']['edges'] as List<dynamic>;
        final pageInfo = data['data']['planConnection']['pageInfo'];
        final List<Map<String, dynamic>> plans = edges
            .map(
              (e) => {
                'start': e['node']['start'],
                'end': e['node']['end'],
                'legs': e['node']['legs'],
              },
            )
            .toList();
        return {'plans': await Plan.parseAll(plans), 'pageInfo': pageInfo};
      } else {
        debugPrint(resp.body);
        throw Exception('No plan found. Check your input.');
      }
    } else {
      throw Exception('Error from backend: ${resp.statusCode}');
    }
  }
}
