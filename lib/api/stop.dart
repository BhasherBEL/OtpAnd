import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/timed_pattern.dart';
import 'package:otpand/objects/timed_stop.dart';
import 'package:intl/intl.dart';

Future<List<TimedStop>> fetchNextDepartures(Stop stop) async {
  final String gql = '''
    query NextDepartures(\$id: String!) {
      stop(id: \$id) {
        stoptimesWithoutPatterns(omitNonPickups: true, omitCanceled: true) {
					headsign
					scheduledDeparture
					realtimeDeparture
					serviceDay
					realtime
					realtimeArrival
					scheduledArrival
					trip {
						gtfsId
						tripHeadsign
						tripShortName
						route {
							gtfsId
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
      'variables': {'id': stop.gtfsId},
    }),
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    if (data['data'] != null &&
        data['data']['stop'] != null &&
        data['data']['stop']['stoptimesWithoutPatterns'] != null) {
      final stoptimesWithoutPatterns =
          data['data']['stop']['stoptimesWithoutPatterns'] as List;
      return Future.wait(
        stoptimesWithoutPatterns.map(
          (json) =>
              TimedStop.parseFromStoptime(stop, json as Map<String, dynamic>),
        ),
      );
    } else {
      throw Exception('No stoptimes found for this stop.');
    }
  } else {
    throw Exception('Error from backend: ${resp.statusCode}');
  }
}

Future<List<TimedPattern>> fetchTimetable(Stop stop, DateTime date) async {
  final dateStr = DateFormat('yyyy-MM-dd').format(date);

  final String gql = '''
		query Timetable(\$id: String!, \$date: String!) {
			stop(id: \$id) {
				stoptimesForServiceDate(date: \$date, omitNonPickups: true, omitCanceled: true) {
					pattern {
						headsign
						route {
							gtfsId
						}
					}
					stoptimes {
						serviceDay
						scheduledArrival
						scheduledDeparture
					  trip {
              gtfsId
              tripHeadsign
              tripShortName
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
      'variables': {'id': stop.gtfsId, 'date': dateStr},
    }),
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    if (data['data'] != null &&
        data['data']['stop'] != null &&
        data['data']['stop']['stoptimesForServiceDate'] != null) {
      final stoptimesForServiceDate =
          data['data']['stop']['stoptimesForServiceDate'] as List;
      return (await Future.wait(
            stoptimesForServiceDate.map(
              (json) => TimedPattern.parseFromStoptimesInPattern(
                stop,
                json as Map<String, dynamic>,
              ),
            ),
          ))
          .where((pattern) => pattern != null && pattern.timedStops.isNotEmpty)
          .cast<TimedPattern>()
          .toList();
    } else {
      throw Exception('No timetable found for this stop and date.');
    }
  } else {
    throw Exception('Error from backend: ${resp.statusCode}');
  }
}
