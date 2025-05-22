import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/trip.dart';
import 'package:otpand/objs.dart';

class TimedStop {
  final Stop stop;
  final DepartureArrival arrival;
  final DepartureArrival departure;
  final String? headSign;
  final Trip? trip;

  TimedStop({
    required this.stop,
    required this.arrival,
    required this.departure,
    this.headSign,
    this.trip,
  });

  static Future<TimedStop> parseFromStoptime(
    Stop stop,
    Map<String, dynamic> json,
  ) async {
    final bool realtime = json['realtime'] == true;
    final int serviceDay = json['serviceDay'] ?? 0;

    String? toIso(int? secondsSinceMidnight) {
      if (secondsSinceMidnight == null) return null;
      final int unix = serviceDay + secondsSinceMidnight;
      return DateTime.fromMillisecondsSinceEpoch(unix * 1000).toIso8601String();
    }

    final String? scheduledArrival = toIso(json['scheduledArrival']);
    final String? realtimeArrival = toIso(json['realtimeArrival']);
    final String? scheduledDeparture = toIso(json['scheduledDeparture']);
    final String? realtimeDeparture = toIso(json['realtimeDeparture']);

    return TimedStop(
      stop: stop,
      arrival: DepartureArrival(
        scheduledTime: scheduledArrival,
        estimated:
            realtime ? EstimatedTime(time: realtimeArrival, delay: null) : null,
      ),
      departure: DepartureArrival(
        scheduledTime: scheduledDeparture,
        estimated:
            realtime
                ? EstimatedTime(time: realtimeDeparture, delay: null)
                : null,
      ),
      headSign: json['headsign'] as String?,
      trip: json['trip'] != null ? await Trip.parse(json['trip']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stop': stop.toMap(),
      'arrival': arrival,
      'departure': departure,
      'headSign': headSign,
      'trip': trip?.toMap(),
    };
  }
}
