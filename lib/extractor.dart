import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/timedStop.dart';

import 'objs.dart';

Future<Plan> parsePlan(Map<String, dynamic> planJson) async {
  List<Leg> legs = [];

  for (final legJson in planJson['legs']) {
    legs.add(await parseLeg(legJson as Map<String, dynamic>));
  }

  return Plan(
    start: planJson['start'] ?? '',
    end: planJson['end'] ?? '',
    legs: legs,
  );
}

Future<Leg> parseLeg(Map<String, dynamic> legJson) async {
  final route =
      legJson['route'] != null
          ? await RouteDao().get(legJson['route']['gtfsId'] as String)
          : null;

  List<TimedStop>? intermediateStops;

  if (legJson['intermediatePlaces'] != null) {
    intermediateStops = [];
    for (final s in legJson['intermediatePlaces'] as List) {
      final stop = await StopDao().get(s['stop']['gtfsId'] as String);
      if (stop != null) {
        intermediateStops.add(
          TimedStop(
            stop: stop,
            arrival: DepartureArrival.parse(s['arrival']),
            departure: DepartureArrival.parse(s['departure']),
          ),
        );
      }
    }
  }

  final List<DepartureArrival> otherDepartures = [];
  if (legJson['previousLegs'] != null) {
    for (final leg in legJson['previousLegs']) {
      if (leg['from']['departure'] != null) {
        otherDepartures.add(DepartureArrival.parse(leg['from']['departure']));
      }
    }
  }
  if (legJson['nextLegs'] != null) {
    for (final leg in legJson['nextLegs']) {
      if (leg['from']['departure'] != null) {
        otherDepartures.add(DepartureArrival.parse(leg['from']['departure']));
      }
    }
  }
  print(otherDepartures);

  return Leg(
    id: legJson['id'] as String?,
    mode: legJson['mode'] ?? '',
    headsign: legJson['headsign'],
    transitLeg: legJson['transitLeg'] as bool,
    realTime: legJson['realTime'] as bool,
    from: parsePlace(legJson['from'] as Map<String, dynamic>),
    to: parsePlace(legJson['to'] as Map<String, dynamic>),
    route: route,
    duration: legJson['duration'] as num,
    distance: legJson['distance'] as num,
    intermediateStops: intermediateStops,
    interlineWithPreviousLeg: legJson['interlineWithPreviousLeg'] as bool,
    otherDepartures: otherDepartures,
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
    delay: estJson['delay'] as String?,
  );
}

Future<List<Plan>> parsePlans(List<dynamic> rawPlans) async {
  return await Future.wait(
    rawPlans.map((e) => parsePlan(e as Map<String, dynamic>)),
  );
}

Location parseLocation(Map<String, dynamic> locationJson) {
  return Location(
    name: locationJson['name'] ?? '',
    displayName: locationJson['name'] ?? 'Unknown',
    lat: double.parse((locationJson['lat'] as String?) ?? '0.0'),
    lon: double.parse((locationJson['lon'] as String?) ?? '0.0'),
  );
}
