import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/timed_stop.dart';

class TimedPattern {
  final List<TimedStop> timedStops;
  final String? headSign;
  final RouteInfo route;

  TimedPattern({
    required this.timedStops,
    required this.headSign,
    required this.route,
  });

  static Future<TimedPattern?> parseFromStoptimesInPattern(
    Stop stop,
    Map<String, dynamic> json,
  ) async {
    if (json['pattern'] == null) return null;

    final route = await RouteDao().get(
      json['pattern']['route']['gtfsId'] as String,
    );
    if (route == null) return null;

    return TimedPattern(
      route: route,
      headSign: json['pattern']['headsign'] as String?,
      timedStops: await TimedStop.parseAllFromStoptimes(
        stop,
        json['stoptimes'] as List<dynamic>,
      ),
    );
  }
}
