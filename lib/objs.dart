import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/stop.dart';

class Plan {
  final String start;
  final String end;
  final List<Leg> legs;

  Plan({required this.start, required this.end, required this.legs});
}

class Leg {
  final String mode;
  final String? headsign;
  final bool transitLeg;
  final Place from;
  final Place to;
  final RouteInfo? route;
  final num duration;
  final num distance;
  final List<Stop>? intermediateStops;
  final bool interlineWithPreviousLeg;

  Leg({
    required this.mode,
    this.headsign,
    required this.transitLeg,
    required this.from,
    required this.to,
    this.route,
    required this.duration,
    required this.distance,
    this.intermediateStops,
    required this.interlineWithPreviousLeg,
  });
}

class Place {
  final String name;
  final double lat;
  final double lon;
  final DepartureArrival? departure;
  final DepartureArrival? arrival;

  Place({
    required this.name,
    required this.lat,
    required this.lon,
    this.departure,
    this.arrival,
  });
}

class DepartureArrival {
  final String? scheduledTime;
  final EstimatedTime? estimated;

  DepartureArrival({this.scheduledTime, this.estimated});
}

class EstimatedTime {
  final String? time;
  final int? delay;

  EstimatedTime({this.time, this.delay});
}

class Location {
  final String name;
  final String displayName;
  final double lat;
  final double lon;

  Location({
    required this.name,
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}
