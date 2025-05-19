import 'package:otpand/objects/stop.dart';
import 'package:otpand/objs.dart';

class TimedStop {
  final Stop stop;
  final DepartureArrival arrival;
  final DepartureArrival departure;
  final String? headSign;

  TimedStop({
    required this.stop,
    required this.arrival,
    required this.departure,
    this.headSign,
  });

  static TimedStop parse(Map<String, dynamic> json) {
    return TimedStop(
      stop: Stop.parse(json['stop'] as Map<String, dynamic>),
      arrival: DepartureArrival.parse(json['arrival'] as Map<String, dynamic>),
      departure: DepartureArrival.parse(
        json['departure'] as Map<String, dynamic>,
      ),
      headSign: json['headSign'] as String?,
    );
  }

  static TimedStop parseFromStoptime(Stop stop, Map<String, dynamic> json) {
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
    );
  }

  static List<TimedStop> parseAll(List<dynamic> list) {
    return list.map((e) => TimedStop.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'stop': stop.toMap(),
      'arrival': arrival,
      'departure': departure,
      'headSign': headSign,
    };
  }
}
