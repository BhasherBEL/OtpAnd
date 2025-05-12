import 'objs.dart';

Plan parsePlan(Map<String, dynamic> planJson) {
  return Plan(
    start: planJson['start'] ?? '',
    end: planJson['end'] ?? '',
    legs:
        (planJson['legs'] as List)
            .map((leg) => parseLeg(leg as Map<String, dynamic>))
            .toList(),
  );
}

Leg parseLeg(Map<String, dynamic> legJson) {
  return Leg(
    mode: legJson['mode'] ?? '',
    from: parsePlace(legJson['from'] as Map<String, dynamic>),
    to: parsePlace(legJson['to'] as Map<String, dynamic>),
    route:
        legJson['route'] != null
            ? parseRouteInfo(legJson['route'] as Map<String, dynamic>)
            : null,
    legGeometry:
        legJson['legGeometry'] != null
            ? parseLegGeometry(legJson['legGeometry'] as Map<String, dynamic>)
            : null,
  );
}

Place parsePlace(Map<String, dynamic> placeJson) {
  return Place(
    name: placeJson['name'] ?? '',
    lat: (placeJson['lat'] as num?)?.toDouble() ?? 0.0,
    lon: (placeJson['lon'] as num?)?.toDouble() ?? 0.0,
    departure:
        placeJson['departure'] != null
            ? parseDepartureArrival(
              placeJson['departure'] as Map<String, dynamic>,
            )
            : null,
    arrival:
        placeJson['arrival'] != null
            ? parseDepartureArrival(
              placeJson['arrival'] as Map<String, dynamic>,
            )
            : null,
  );
}

DepartureArrival parseDepartureArrival(Map<String, dynamic> daJson) {
  return DepartureArrival(
    scheduledTime: daJson['scheduledTime'] as String?,
    estimated:
        daJson['estimated'] != null
            ? parseEstimatedTime(daJson['estimated'] as Map<String, dynamic>)
            : null,
  );
}

EstimatedTime parseEstimatedTime(Map<String, dynamic> estJson) {
  return EstimatedTime(
    time: estJson['time'] as String?,
    delay: estJson['delay'] as int?,
  );
}

RouteInfo parseRouteInfo(Map<String, dynamic> routeJson) {
  return RouteInfo(
    gtfsId: routeJson['gtfsId'] as String?,
    longName: routeJson['longName'] as String?,
    shortName: routeJson['shortName'] as String?,
  );
}

LegGeometry parseLegGeometry(Map<String, dynamic> geomJson) {
  return LegGeometry(points: geomJson['points'] as String?);
}

/// Parse a list of plans from the raw API result
List<Plan> parsePlans(List<dynamic> rawPlans) {
  return rawPlans.map((e) => parsePlan(e as Map<String, dynamic>)).toList();
}
