class Plan {
  final String start;
  final String end;
  final List<Leg> legs;

  Plan({required this.start, required this.end, required this.legs});
}

class Leg {
  final String mode;
  final Place from;
  final Place to;
  final RouteInfo? route;
  final LegGeometry? legGeometry;

  Leg({
    required this.mode,
    required this.from,
    required this.to,
    this.route,
    this.legGeometry,
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

class RouteInfo {
  final String? gtfsId;
  final String? longName;
  final String? shortName;

  RouteInfo({this.gtfsId, this.longName, this.shortName});
}

class LegGeometry {
  final String? points;

  LegGeometry({this.points});
}
