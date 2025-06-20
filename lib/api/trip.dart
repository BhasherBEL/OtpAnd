import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/objects/trip.dart';
import 'package:otpand/objects/timed_stop.dart';

Future<List<TimedStop>> fetchTrip(Trip trip, String serviceDate) async {
  final String gql = '''
    query TripStoptimes(\$id: String!, \$serviceDate: String!) {
      trip(id: \$id) {
        stoptimesForDate (serviceDate: \$serviceDate) {
          stop {
            gtfsId
          }
          scheduledDeparture
          realtimeDeparture
          realtime
          realtimeArrival
          scheduledArrival
					serviceDay
					dropoffType
					pickupType
        }
      }
    }
  ''';

  final resp = await http.post(
    Uri.parse('https://maps.bhasher.com/otp/gtfs/v1'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'query': gql,
      'variables': {'id': trip.gtfsId, 'serviceDate': serviceDate},
    }),
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    if (data['data'] != null &&
        data['data']['trip'] != null &&
        data['data']['trip']['stoptimesForDate'] != null) {
      final stoptimes = data['data']['trip']['stoptimesForDate'] as List;
      return Future.wait(
        stoptimes.map(
          (json) =>
              TimedStop.parseFromStoptime(null, json as Map<String, dynamic>),
        ),
      );
    } else {
      throw Exception('No stoptimes found for this trip.');
    }
  } else {
    throw Exception('Error from backend: ${resp.statusCode}');
  }
}
