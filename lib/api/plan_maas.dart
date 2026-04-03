import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/place.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/trip.dart';
import 'package:otpand/utils.dart';

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

/// Converts GTFS-style seconds-since-midnight to an ISO 8601 string.
///
/// Handles times that exceed 86 400 (midnight rollover), e.g. `90 000` →
/// next-day 01:00.
String maasSecondsToIso(int seconds, DateTime queryDate) {
  final midnight = DateTime(queryDate.year, queryDate.month, queryDate.day);
  return midnight.add(Duration(seconds: seconds)).toIso8601String();
}

/// Maps a maas-rs `PlanRouteType` enum value to an OtpAnd mode string.
String maasRouteTypeToMode(String? routeType) {
  switch (routeType?.toUpperCase()) {
    case 'BUS':
    case 'COACH':
      return 'BUS';
    case 'RAIL':
    case 'CABLECAR':
    case 'GONDOLA':
    case 'FUNICULAR':
      return 'RAIL';
    case 'SUBWAY':
      return 'SUBWAY';
    case 'TRAMWAY':
      return 'TRAM';
    case 'FERRY':
      return 'FERRY';
    case 'TAXI':
      return 'CAR';
    default:
      return 'BUS';
  }
}

// ---------------------------------------------------------------------------
// Place parsing
// ---------------------------------------------------------------------------

/// Parses a maas-rs `PlanPlace` JSON (with nested `node`) into a [Place].
///
/// No DB calls — fully synchronous and unit-testable.
Place parseMaasPlace(Map<String, dynamic> placeJson, DateTime queryDate) {
  final node = placeJson['node'] as Map<String, dynamic>?;
  final lat = (node?['lat'] as num?)?.toDouble() ?? 0.0;
  final lon = (node?['lon'] as num?)?.toDouble() ?? 0.0;
  final name = (node?['name'] as String?) ?? 'Unknown';

  final departureSeconds = placeJson['departure'] as int?;
  final arrivalSeconds = placeJson['arrival'] as int?;

  final departure = departureSeconds != null
      ? DepartureArrival(
          scheduledTime: maasSecondsToIso(departureSeconds, queryDate),
        )
      : null;
  final arrival = arrivalSeconds != null
      ? DepartureArrival(
          scheduledTime: maasSecondsToIso(arrivalSeconds, queryDate),
        )
      : null;

  return Place(
    name: name,
    lat: lat,
    lon: lon,
    departure: departure,
    arrival: arrival,
    // No stop object — maas-rs does not expose GTFS stop IDs
  );
}

// ---------------------------------------------------------------------------
// Geometry parsing
// ---------------------------------------------------------------------------

/// Converts a maas-rs `geometry` JSON array of `{ lat, lon }` objects into a
/// list of [LatLng] points.  Returns `null` when the array is absent or empty.
List<LatLng>? _parseGeometryPoints(List<dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  return json
      .map(
        (p) => LatLng(
          (p['lat'] as num).toDouble(),
          (p['lon'] as num).toDouble(),
        ),
      )
      .toList();
}

// ---------------------------------------------------------------------------
// Leg parsing
// ---------------------------------------------------------------------------

/// Parses a maas-rs `PlanTransitLeg` JSON into a [Leg].
///
/// No DB calls — fully synchronous and unit-testable.
///
/// **Not available from maas-rs (see MISSING_FEATURES.md):**
/// - Leg geometry / polyline
/// - Intermediate stops
/// - Real-time flag
/// - Service date
/// - GTFS IDs (placeholders used)
Leg parseMaasTransitLeg(Map<String, dynamic> legJson, DateTime queryDate) {
  final from = parseMaasPlace(
    legJson['from'] as Map<String, dynamic>,
    queryDate,
  );
  final to = parseMaasPlace(
    legJson['to'] as Map<String, dynamic>,
    queryDate,
  );

  final tripJson = legJson['trip'] as Map<String, dynamic>?;
  final routeJson = tripJson?['route'] as Map<String, dynamic>?;

  final String mode =
      maasRouteTypeToMode(routeJson?['mode'] as String?);
  final String? headsign = tripJson?['headsign'] as String?;
  final String routeShortName = (routeJson?['shortName'] as String?) ?? '';
  final String routeLongName = (routeJson?['longName'] as String?) ?? '';

  final RouteInfo? route = routeJson != null
      ? RouteInfo(
          gtfsId: 'maas:${routeShortName.isNotEmpty ? routeShortName : mode}',
          longName: routeLongName,
          shortName: routeShortName,
          color: getColorFromCode(routeJson['color']),
          textColor: getColorFromCode(routeJson['textColor']),
          mode: RouteMode.fromString(mode),
        )
      : null;

  final Trip? trip = tripJson != null
      ? Trip(
          gtfsId:
              'maas:${routeShortName.isNotEmpty ? routeShortName : mode}_${headsign ?? ""}',
          headsign: headsign,
          shortName: routeShortName.isNotEmpty ? routeShortName : null,
          route: route,
        )
      : null;

  // Alternative departures (previous / next)
  final List<Leg> otherDepartures = [];
  final prevJson = legJson['previousDepartures'] as List<dynamic>?;
  if (prevJson != null) {
    for (final dep in prevJson) {
      if (dep == null) continue;
      otherDepartures.add(
        parseMaasTransitLeg(dep as Map<String, dynamic>, queryDate),
      );
    }
  }
  final nextJson = legJson['nextDepartures'] as List<dynamic>?;
  if (nextJson != null) {
    for (final dep in nextJson) {
      if (dep == null) continue;
      otherDepartures.add(
        parseMaasTransitLeg(dep as Map<String, dynamic>, queryDate),
      );
    }
  }

  final riskJson = legJson['transferRisk'] as Map<String, dynamic>?;
  final transferRisk = riskJson != null ? TransferRisk.fromJson(riskJson) : null;

  return Leg(
    id: null, // maas-rs does not assign leg IDs
    mode: mode,
    headsign: headsign,
    transitLeg: true,
    realTime: false, // maas-rs does not provide real-time data
    from: from,
    to: to,
    route: route,
    trip: trip,
    duration: (legJson['duration'] as int?) ?? 0,
    distance: (legJson['length'] as int?) ?? 0,
    tripStops: null, // maas-rs does not expose intermediate stops
    interlineWithPreviousLeg: false, // not tracked by maas-rs
    otherDepartures: otherDepartures,
    serviceDate: null, // not exposed by maas-rs
    geometry: null,
    geometryPoints: _parseGeometryPoints(legJson['geometry'] as List<dynamic>?),
    transferRisk: transferRisk,
  );
}

/// Parses a maas-rs `PlanWalkLeg` JSON into a [Leg].
///
/// No DB calls — fully synchronous and unit-testable.
Leg parseMaasWalkLeg(Map<String, dynamic> legJson, DateTime queryDate) {
  final from = parseMaasPlace(
    legJson['from'] as Map<String, dynamic>,
    queryDate,
  );
  final to = parseMaasPlace(
    legJson['to'] as Map<String, dynamic>,
    queryDate,
  );

  return Leg(
    id: null,
    mode: 'WALK',
    headsign: null,
    transitLeg: false,
    realTime: false,
    from: from,
    to: to,
    route: null,
    trip: null,
    duration: (legJson['duration'] as int?) ?? 0,
    distance: (legJson['length'] as int?) ?? 0,
    tripStops: null,
    interlineWithPreviousLeg: false,
    otherDepartures: const [],
    serviceDate: null,
    geometry: null,
    geometryPoints: _parseGeometryPoints(legJson['geometry'] as List<dynamic>?),
  );
}

/// Dispatches leg parsing to [parseMaasTransitLeg] or [parseMaasWalkLeg]
/// based on the `__typename` field.
Leg parseMaasLeg(Map<String, dynamic> legJson, DateTime queryDate) {
  final typename = legJson['__typename'] as String?;
  if (typename == 'PlanTransitLeg') {
    return parseMaasTransitLeg(legJson, queryDate);
  }
  // Default to walk (covers PlanWalkLeg and any unknown future types)
  return parseMaasWalkLeg(legJson, queryDate);
}

// ---------------------------------------------------------------------------
// Plan parsing
// ---------------------------------------------------------------------------

/// Builds a normalized leg map that is compatible with [Leg.parse].
///
/// Used to populate [Plan.raw] so that plans saved to the local DB can be
/// reloaded later. Route info will be null on reload (no GTFS IDs to look up),
/// but the rest of the leg data is preserved.
Map<String, dynamic> buildRawLeg(Leg leg) {
  return {
    'id': leg.id,
    'mode': leg.mode,
    'headsign': leg.headsign,
    'transitLeg': leg.transitLeg,
    'realTime': leg.realTime,
    'serviceDate': leg.serviceDate,
    'from': {
      'name': leg.from.name,
      'lat': leg.from.lat,
      'lon': leg.from.lon,
      'departure': leg.from.departure?.toMap(),
      'arrival': null,
      'stop': null,
    },
    'to': {
      'name': leg.to.name,
      'lat': leg.to.lat,
      'lon': leg.to.lon,
      'arrival': leg.to.arrival?.toMap(),
      'departure': null,
      'stop': null,
    },
    'route': null,
    'trip': leg.trip != null
        ? {
            'gtfsId': leg.trip!.gtfsId,
            'tripHeadsign': leg.trip!.headsign,
            'tripShortName': leg.trip!.shortName,
          }
        : null,
    'duration': leg.duration,
    'distance': leg.distance,
    'interlineWithPreviousLeg': leg.interlineWithPreviousLeg,
  };
}

/// Parses a maas-rs `Plan` JSON object into a [Plan].
///
/// No DB calls — fully synchronous and unit-testable.
Plan parseMaasPlan(Map<String, dynamic> planJson, DateTime queryDate) {
  final startSeconds = planJson['start'] as int;
  final endSeconds = planJson['end'] as int;
  final start = maasSecondsToIso(startSeconds, queryDate);
  final end = maasSecondsToIso(endSeconds, queryDate);

  final legsJson = planJson['legs'] as List<dynamic>;
  final legs =
      legsJson.map((l) => parseMaasLeg(l as Map<String, dynamic>, queryDate)).toList();

  // Drop trivial walk legs at journey start/end that are artefacts of
  // coordinate-snapping when the user picks a transit stop as origin or
  // destination.  The backend snaps the stop's lat/lng to the nearest OSM
  // node, which may be a few metres away, producing a 1–5 s walk with no
  // meaningful name ("Unknown").  Threshold: strictly less than 60 s / 72 m
  // (= 60 s × 1.2 m/s).  Real first/last walks are always longer.
  bool _isTrivialWalk(Leg l) =>
      !l.transitLeg && l.duration < 60 && l.distance < 72;
  while (legs.isNotEmpty && _isTrivialWalk(legs.first)) {
    legs.removeAt(0);
  }
  while (legs.isNotEmpty && _isTrivialWalk(legs.last)) {
    legs.removeLast();
  }

  // Build a Plan.parse-compatible raw map for DB persistence.
  final raw = {
    'start': start,
    'end': end,
    'legs': legs.map(buildRawLeg).toList(),
  };

  return Plan(
    start: start,
    end: end,
    fromName: legs.isNotEmpty ? legs.first.from.name : 'Unknown departure',
    toName: legs.isNotEmpty ? legs.last.to.name : 'Unknown arrival',
    legs: legs,
    raw: raw,
  );
}

// ---------------------------------------------------------------------------
// GraphQL query
// ---------------------------------------------------------------------------

const String _raptorQuery = r'''
  query RaptorPlan(
    $fromLat: Float!, $fromLng: Float!,
    $toLat: Float!, $toLng: Float!,
    $date: String, $time: String,
    $windowMinutes: Int
  ) {
    raptor(
      fromLat: $fromLat, fromLng: $fromLng,
      toLat: $toLat, toLng: $toLng,
      date: $date, time: $time,
      windowMinutes: $windowMinutes
    ) {
      start
      end
      legs {
        __typename
        ... on PlanWalkLeg {
          start
          end
          duration
          length
          from { arrival departure node { lat lon name mode } }
          to   { arrival departure node { lat lon name mode } }
          geometry { lat lon }
        }
        ... on PlanTransitLeg {
          start
          end
          duration
          length
          from { arrival departure node { lat lon name mode } }
          to   { arrival departure node { lat lon name mode } }
          geometry { lat lon }
          transferRisk {
            reliability
            scheduledDeparture
            nextDeparture
            nextReliability
          }
          trip {
            headsign
            route { shortName longName mode color textColor }
          }
          previousDepartures(count: 1) {
            start end duration
            from { arrival departure node { lat lon name } }
            to   { arrival departure node { lat lon name } }
            trip { headsign route { shortName longName mode color textColor } }
          }
          nextDepartures(count: 2) {
            start end duration
            from { arrival departure node { lat lon name } }
            to   { arrival departure node { lat lon name } }
            trip { headsign route { shortName longName mode color textColor } }
          }
        }
      }
    }
  }
''';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Fetches journey plans from maas-rs using the RAPTOR algorithm.
///
/// Returns a map with:
/// - `plans`: `List<Plan>`
/// - `pageInfo`: synthetic page-info (maas-rs does not paginate)
/// - `searchDateTime`: the query time as ISO 8601 string
///
/// **Limitations vs OTP (see MISSING_FEATURES.md):**
/// - No pagination — all results are returned at once.
/// - Profile preferences and per-mode filters are ignored.
/// - Arrival-time routing is not supported — always departs at [queryDateTime].
Future<Map<String, dynamic>> fetchMaasPlans({
  required Location fromLocation,
  required Location toLocation,
  required DateTime queryDateTime,
  required String maasUrl,
}) async {
  final date = DateFormat('yyyy-MM-dd').format(queryDateTime);
  final time = DateFormat('HH:mm').format(queryDateTime);

  final variables = {
    'fromLat': fromLocation.lat,
    'fromLng': fromLocation.lon,
    'toLat': toLocation.lat,
    'toLng': toLocation.lon,
    'date': date,
    'time': time,
    'windowMinutes': 180,
  };

  final resp = await http.post(
    Uri.parse('$maasUrl/graphql'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': _raptorQuery, 'variables': variables}),
  );

  if (resp.statusCode != 200) {
    throw Exception('Error from maas-rs: ${resp.statusCode}');
  }

  final data = jsonDecode(resp.body) as Map<String, dynamic>;

  if (data['errors'] != null) {
    debugPrint('maas-rs errors: ${data['errors']}');
    throw Exception('maas-rs returned errors. Check your input.');
  }

  if (data['data'] == null || data['data']['raptor'] == null) {
    debugPrint(resp.body);
    throw Exception('No plan found. Check your input.');
  }

  final raptorResults = data['data']['raptor'] as List<dynamic>;
  if (raptorResults.isEmpty) {
    throw Exception('No plan found. Check your input.');
  }

  final plans = raptorResults
      .map((p) => parseMaasPlan(p as Map<String, dynamic>, queryDateTime))
      .toList();

  // Synthetic page-info: maas-rs returns all results at once, no cursors.
  return {
    'plans': plans,
    'pageInfo': {
      'startCursor': null,
      'endCursor': null,
      'hasNextPage': false,
      'hasPreviousPage': false,
      'searchWindowUsed': null,
    },
    'searchDateTime': queryDateTime.toIso8601String(),
  };
}
