import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/timed_stop.dart';

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
