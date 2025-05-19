import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/timedStop.dart';

Future<List<TimedStop>> fetchNextDepartures(Stop stop) async {
  final String gql = '''
    query NextDepartures(\$id: String!) {
      stop(id: \$id) {
        stoptimesWithoutPatterns(omitNonPickups: true) {
          headsign
          scheduledDeparture
          realtimeDeparture
          serviceDay
          realtime
          realtimeArrival
          scheduledArrival
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
      final List stoptimes = data['data']['stop']['stoptimesWithoutPatterns'];
      return stoptimes
          .map<TimedStop>((json) => TimedStop.parseFromStoptime(stop, json))
          .toList();
    } else {
      throw Exception("No stoptimes found for this stop.");
    }
  } else {
    throw Exception("Error from backend: ${resp.statusCode}");
  }
}
