import 'package:otpand/objects/stop.dart';
import 'package:otpand/objs.dart';

class TimedStop {
  final Stop stop;
  final DepartureArrival arrival;
  final DepartureArrival departure;

  TimedStop({
    required this.stop,
    required this.arrival,
    required this.departure,
  });

  static TimedStop parse(Map<String, dynamic> json) {
    return TimedStop(
      stop: Stop.parse(json['stop'] as Map<String, dynamic>),
      arrival: DepartureArrival.parse(json['arrival'] as Map<String, dynamic>),
      departure: DepartureArrival.parse(
        json['departure'] as Map<String, dynamic>,
      ),
    );
  }

  static List<TimedStop> parseAll(List<dynamic> list) {
    return list.map((e) => TimedStop.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {'stop': stop.toMap(), 'arrival': arrival, 'departure': departure};
  }
}
