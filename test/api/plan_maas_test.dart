import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/api/plan_maas.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/place.dart';

void main() {
  // Fixed query date used throughout tests.
  final queryDate = DateTime(2024, 1, 15);

  // ---------------------------------------------------------------------------
  // maasSecondsToIso
  // ---------------------------------------------------------------------------
  group('maasSecondsToIso', () {
    test('midnight (0 s) → same date T00:00:00', () {
      expect(
        maasSecondsToIso(0, queryDate),
        startsWith('2024-01-15T00:00:00'),
      );
    });

    test('10:30 (37 800 s) → same date T10:30:00', () {
      expect(
        maasSecondsToIso(10 * 3600 + 30 * 60, queryDate),
        startsWith('2024-01-15T10:30:00'),
      );
    });

    test('25 h (90 000 s) rolls over to next day T01:00:00', () {
      expect(
        maasSecondsToIso(25 * 3600, queryDate),
        startsWith('2024-01-16T01:00:00'),
      );
    });

    test('end-of-day (86 399 s) stays on same date', () {
      expect(
        maasSecondsToIso(86399, queryDate),
        startsWith('2024-01-15T23:59:59'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // maasRouteTypeToMode
  // ---------------------------------------------------------------------------
  group('maasRouteTypeToMode', () {
    test('BUS → BUS', () => expect(maasRouteTypeToMode('BUS'), 'BUS'));
    test('COACH → BUS', () => expect(maasRouteTypeToMode('COACH'), 'BUS'));
    test('RAIL → RAIL', () => expect(maasRouteTypeToMode('RAIL'), 'RAIL'));
    test('CABLECAR → RAIL', () => expect(maasRouteTypeToMode('CABLECAR'), 'RAIL'));
    test('GONDOLA → RAIL', () => expect(maasRouteTypeToMode('GONDOLA'), 'RAIL'));
    test('FUNICULAR → RAIL', () => expect(maasRouteTypeToMode('FUNICULAR'), 'RAIL'));
    test('SUBWAY → SUBWAY', () => expect(maasRouteTypeToMode('SUBWAY'), 'SUBWAY'));
    test('TRAMWAY → TRAM', () => expect(maasRouteTypeToMode('TRAMWAY'), 'TRAM'));
    test('FERRY → FERRY', () => expect(maasRouteTypeToMode('FERRY'), 'FERRY'));
    test('TAXI → CAR', () => expect(maasRouteTypeToMode('TAXI'), 'CAR'));
    test('case-insensitive: bus → BUS', () => expect(maasRouteTypeToMode('bus'), 'BUS'));
    test('null → BUS (default)', () => expect(maasRouteTypeToMode(null), 'BUS'));
    test('unknown string → BUS (default)', () => expect(maasRouteTypeToMode('AIR'), 'BUS'));
  });

  // ---------------------------------------------------------------------------
  // parseMaasPlace
  // ---------------------------------------------------------------------------
  group('parseMaasPlace', () {
    test('parses name, lat, lon from node', () {
      final json = {
        'departure': null,
        'arrival': null,
        'node': {'lat': 50.85045, 'lon': 4.34878, 'name': 'Bruxelles-Midi'},
      };
      final place = parseMaasPlace(json, queryDate);
      expect(place.name, 'Bruxelles-Midi');
      expect(place.lat, closeTo(50.85045, 1e-5));
      expect(place.lon, closeTo(4.34878, 1e-5));
    });

    test('departure seconds convert to ISO departure', () {
      final json = {
        'departure': 36000, // 10:00
        'arrival': null,
        'node': {'lat': 50.8, 'lon': 4.3, 'name': 'Stop A'},
      };
      final place = parseMaasPlace(json, queryDate);
      expect(place.departure?.scheduledTime, startsWith('2024-01-15T10:00:00'));
      expect(place.arrival, isNull);
    });

    test('arrival seconds convert to ISO arrival', () {
      final json = {
        'departure': null,
        'arrival': 39600, // 11:00
        'node': {'lat': 50.9, 'lon': 4.4, 'name': 'Stop B'},
      };
      final place = parseMaasPlace(json, queryDate);
      expect(place.arrival?.scheduledTime, startsWith('2024-01-15T11:00:00'));
      expect(place.departure, isNull);
    });

    test('both departure and arrival may be set', () {
      final json = {
        'departure': 37200, // 10:20
        'arrival': 36900, // 10:15
        'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Transfer Stop'},
      };
      final place = parseMaasPlace(json, queryDate);
      expect(place.departure, isNotNull);
      expect(place.arrival, isNotNull);
    });

    test('falls back gracefully when node is null', () {
      final json = {'departure': null, 'arrival': null, 'node': null};
      final place = parseMaasPlace(json, queryDate);
      expect(place.name, 'Unknown');
      expect(place.lat, 0.0);
      expect(place.lon, 0.0);
    });

    test('stop is always null (maas-rs has no GTFS stop IDs)', () {
      final json = {
        'departure': 36000,
        'arrival': null,
        'node': {'lat': 50.8, 'lon': 4.3, 'name': 'Stop'},
      };
      expect(parseMaasPlace(json, queryDate).stop, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // parseMaasWalkLeg
  // ---------------------------------------------------------------------------
  group('parseMaasWalkLeg', () {
    Map<String, dynamic> makeWalkJson({int start = 36000, int end = 37200}) => {
          '__typename': 'PlanWalkLeg',
          'start': start,
          'end': end,
          'duration': end - start,
          'from': {
            'departure': start,
            'arrival': null,
            'node': {'lat': 50.8, 'lon': 4.3, 'name': 'Start'},
          },
          'to': {
            'departure': null,
            'arrival': end,
            'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Stop A'},
          },
        };

    test('mode is WALK', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).mode, 'WALK');
    });

    test('transitLeg is false', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).transitLeg, isFalse);
    });

    test('realTime is false (maas-rs has no real-time)', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).realTime, isFalse);
    });

    test('duration matches JSON field', () {
      expect(
        parseMaasWalkLeg(makeWalkJson(start: 36000, end: 37200), queryDate).duration,
        1200,
      );
    });

    test('distance is 0 (maas-rs does not return leg distances)', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).distance, 0);
    });

    test('id is null (maas-rs does not assign leg IDs)', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).id, isNull);
    });

    test('geometry (encoded polyline) is null — maas-rs uses geometryPoints', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).geometry, isNull);
    });

    test('geometryPoints is null when geometry absent from JSON', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).geometryPoints, isNull);
    });

    test('geometryPoints is parsed when geometry present in JSON', () {
      final json = {
        '__typename': 'PlanWalkLeg',
        'start': 36000,
        'end': 37200,
        'duration': 1200,
        'from': {
          'departure': 36000,
          'arrival': null,
          'node': {'lat': 50.8, 'lon': 4.3, 'name': 'Start'},
        },
        'to': {
          'departure': null,
          'arrival': 37200,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Stop A'},
        },
        'geometry': [
          {'lat': 50.8, 'lon': 4.3},
          {'lat': 50.82, 'lon': 4.32},
          {'lat': 50.85, 'lon': 4.35},
        ],
      };
      final leg = parseMaasWalkLeg(json, queryDate);
      expect(leg.geometryPoints, isNotNull);
      expect(leg.geometryPoints!, hasLength(3));
      expect(leg.geometryPoints!.first.latitude, closeTo(50.8, 1e-5));
      expect(leg.geometryPoints!.last.longitude, closeTo(4.35, 1e-5));
    });

    test('otherDepartures is empty for walk legs', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).otherDepartures, isEmpty);
    });

    test('tripStops is null (no intermediate stops)', () {
      expect(parseMaasWalkLeg(makeWalkJson(), queryDate).tripStops, isNull);
    });

    test('from.departure is set to leg start time', () {
      final leg = parseMaasWalkLeg(makeWalkJson(start: 36000), queryDate);
      expect(leg.from.departure?.scheduledTime, startsWith('2024-01-15T10:00:00'));
    });

    test('to.arrival is set to leg end time', () {
      final leg = parseMaasWalkLeg(makeWalkJson(end: 37200), queryDate);
      expect(leg.to.arrival?.scheduledTime, startsWith('2024-01-15T10:20:00'));
    });
  });

  // ---------------------------------------------------------------------------
  // parseMaasTransitLeg
  // ---------------------------------------------------------------------------
  group('parseMaasTransitLeg', () {
    Map<String, dynamic> makeTransitJson({
      int start = 37200,
      int end = 41400,
      String headsign = 'City Centre',
      String routeMode = 'BUS',
      String shortName = '42',
      String longName = 'Line 42',
      String? color,
      String? textColor,
      List<Map<String, dynamic>> previousDepartures = const [],
      List<Map<String, dynamic>> nextDepartures = const [],
    }) =>
        {
          '__typename': 'PlanTransitLeg',
          'start': start,
          'end': end,
          'duration': end - start,
          'from': {
            'departure': start,
            'arrival': null,
            'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Stop A'},
          },
          'to': {
            'departure': null,
            'arrival': end,
            'node': {'lat': 50.9, 'lon': 4.4, 'name': 'Stop B'},
          },
          'trip': {
            'headsign': headsign,
            'route': {
              'shortName': shortName,
              'longName': longName,
              'mode': routeMode,
              'color': color,
              'textColor': textColor,
            },
          },
          'previousDepartures': previousDepartures,
          'nextDepartures': nextDepartures,
        };

    test('transitLeg is true', () {
      expect(parseMaasTransitLeg(makeTransitJson(), queryDate).transitLeg, isTrue);
    });

    test('BUS route type → BUS mode', () {
      expect(parseMaasTransitLeg(makeTransitJson(routeMode: 'BUS'), queryDate).mode, 'BUS');
    });

    test('TRAMWAY route type → TRAM mode', () {
      expect(parseMaasTransitLeg(makeTransitJson(routeMode: 'TRAMWAY'), queryDate).mode, 'TRAM');
    });

    test('RAIL route type → RAIL mode', () {
      expect(parseMaasTransitLeg(makeTransitJson(routeMode: 'RAIL'), queryDate).mode, 'RAIL');
    });

    test('SUBWAY route type → SUBWAY mode', () {
      expect(parseMaasTransitLeg(makeTransitJson(routeMode: 'SUBWAY'), queryDate).mode, 'SUBWAY');
    });

    test('headsign is parsed from trip', () {
      final leg = parseMaasTransitLeg(makeTransitJson(headsign: 'North'), queryDate);
      expect(leg.headsign, 'North');
    });

    test('route short name is set', () {
      final leg = parseMaasTransitLeg(makeTransitJson(shortName: '42'), queryDate);
      expect(leg.route?.shortName, '42');
    });

    test('route long name is set', () {
      final leg = parseMaasTransitLeg(makeTransitJson(longName: 'Test Line'), queryDate);
      expect(leg.route?.longName, 'Test Line');
    });

    test('trip headsign matches leg headsign', () {
      final leg = parseMaasTransitLeg(makeTransitJson(headsign: 'South'), queryDate);
      expect(leg.trip?.headsign, 'South');
    });

    test('realTime is false', () {
      expect(parseMaasTransitLeg(makeTransitJson(), queryDate).realTime, isFalse);
    });

    test('distance is 0', () {
      expect(parseMaasTransitLeg(makeTransitJson(), queryDate).distance, 0);
    });

    test('tripStops is null (no intermediate stops)', () {
      expect(parseMaasTransitLeg(makeTransitJson(), queryDate).tripStops, isNull);
    });

    test('id is null', () {
      expect(parseMaasTransitLeg(makeTransitJson(), queryDate).id, isNull);
    });

    test('route color is null when color absent from JSON', () {
      expect(parseMaasTransitLeg(makeTransitJson(), queryDate).route?.color, isNull);
    });

    test('route color is parsed when color present in JSON', () {
      final leg = parseMaasTransitLeg(makeTransitJson(color: 'ADD8E6'), queryDate);
      expect(leg.route?.color, isNotNull);
      expect(leg.route!.color!.value, 0xFFADD8E6);
    });

    test('null trip JSON produces null route and trip', () {
      final json = {
        '__typename': 'PlanTransitLeg',
        'start': 37200,
        'end': 41400,
        'duration': 4200,
        'from': {
          'departure': 37200,
          'arrival': null,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Stop A'},
        },
        'to': {
          'departure': null,
          'arrival': 41400,
          'node': {'lat': 50.9, 'lon': 4.4, 'name': 'Stop B'},
        },
        'trip': null,
        'previousDepartures': <dynamic>[],
        'nextDepartures': <dynamic>[],
      };
      final leg = parseMaasTransitLeg(json, queryDate);
      expect(leg.route, isNull);
      expect(leg.trip, isNull);
    });

    test('previousDepartures are included in otherDepartures', () {
      final prevDep = {
        'start': 33600,
        'end': 37800,
        'duration': 4200,
        'from': {
          'departure': 33600,
          'arrival': null,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Stop A'},
        },
        'to': {
          'departure': null,
          'arrival': 37800,
          'node': {'lat': 50.9, 'lon': 4.4, 'name': 'Stop B'},
        },
        'trip': {
          'headsign': 'City Centre',
          'route': {'shortName': '42', 'longName': 'Line 42', 'mode': 'BUS'},
        },
        'previousDepartures': <dynamic>[],
        'nextDepartures': <dynamic>[],
      };
      final leg = parseMaasTransitLeg(
        makeTransitJson(previousDepartures: [prevDep]),
        queryDate,
      );
      expect(leg.otherDepartures, hasLength(1));
      expect(leg.otherDepartures.first.mode, 'BUS');
    });

    test('nextDepartures are included in otherDepartures after previous', () {
      final nextDep = {
        'start': 40800,
        'end': 45000,
        'duration': 4200,
        'from': {
          'departure': 40800,
          'arrival': null,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Stop A'},
        },
        'to': {
          'departure': null,
          'arrival': 45000,
          'node': {'lat': 50.9, 'lon': 4.4, 'name': 'Stop B'},
        },
        'trip': {
          'headsign': 'City Centre',
          'route': {'shortName': '42', 'longName': 'Line 42', 'mode': 'BUS'},
        },
        'previousDepartures': <dynamic>[],
        'nextDepartures': <dynamic>[],
      };
      final leg = parseMaasTransitLeg(
        makeTransitJson(nextDepartures: [nextDep]),
        queryDate,
      );
      expect(leg.otherDepartures, hasLength(1));
    });

    test('empty previousDepartures / nextDepartures → empty otherDepartures', () {
      final leg = parseMaasTransitLeg(makeTransitJson(), queryDate);
      expect(leg.otherDepartures, isEmpty);
    });

    test('geometryPoints is null when geometry absent from JSON', () {
      expect(
        parseMaasTransitLeg(makeTransitJson(), queryDate).geometryPoints,
        isNull,
      );
    });

    test('geometryPoints is parsed when geometry present in JSON', () {
      final json = makeTransitJson()
        ..['geometry'] = [
          {'lat': 50.85, 'lon': 4.35},
          {'lat': 50.87, 'lon': 4.37},
          {'lat': 50.9, 'lon': 4.4},
        ];
      final leg = parseMaasTransitLeg(json, queryDate);
      expect(leg.geometryPoints, isNotNull);
      expect(leg.geometryPoints!, hasLength(3));
      expect(leg.geometryPoints!.first.latitude, closeTo(50.85, 1e-5));
    });
  });

  // ---------------------------------------------------------------------------
  // parseMaasTransitLeg – transferRisk
  // ---------------------------------------------------------------------------
  group('parseMaasTransitLeg – transferRisk', () {
    Map<String, dynamic> baseTransitJson() => {
          'start': 36000,
          'end': 37800,
          'duration': 1800,
          'from': {'departure': 36000, 'arrival': null, 'node': {'lat': 50.8, 'lon': 4.3, 'name': 'A', 'mode': null}},
          'to':   {'departure': null, 'arrival': 37800, 'node': {'lat': 50.9, 'lon': 4.4, 'name': 'B', 'mode': null}},
          'geometry': null,
          'trip': null,
          'previousDepartures': null,
          'nextDepartures': null,
        };

    test('null transferRisk field → leg.transferRisk is null', () {
      final json = baseTransitJson()..['transferRisk'] = null;
      final leg = parseMaasTransitLeg(json, queryDate);
      expect(leg.transferRisk, isNull);
    });

    test('parses reliability and scheduledDeparture', () {
      final json = baseTransitJson()
        ..['transferRisk'] = {
          'reliability': 0.73,
          'scheduledDeparture': 36000,
          'nextDeparture': 37200,
        };
      final leg = parseMaasTransitLeg(json, queryDate);
      expect(leg.transferRisk?.reliability, closeTo(0.73, 1e-5));
      expect(leg.transferRisk?.scheduledDeparture, 36000);
      expect(leg.transferRisk?.nextDeparture, 37200);
      expect(leg.transferRisk?.waitIfMissedSecs, 1200);
    });

    test('nextDeparture null → waitIfMissedSecs is null', () {
      final json = baseTransitJson()
        ..['transferRisk'] = {
          'reliability': 0.4,
          'scheduledDeparture': 36000,
          'nextDeparture': null,
        };
      final leg = parseMaasTransitLeg(json, queryDate);
      expect(leg.transferRisk?.waitIfMissedSecs, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // parseMaasLeg dispatch
  // ---------------------------------------------------------------------------
  group('parseMaasLeg', () {
    test('PlanWalkLeg typename → walk leg', () {
      final json = {
        '__typename': 'PlanWalkLeg',
        'start': 36000,
        'end': 37200,
        'duration': 1200,
        'from': {
          'departure': 36000,
          'arrival': null,
          'node': {'lat': 50.8, 'lon': 4.3, 'name': 'A'},
        },
        'to': {
          'departure': null,
          'arrival': 37200,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'B'},
        },
      };
      final leg = parseMaasLeg(json, queryDate);
      expect(leg.mode, 'WALK');
      expect(leg.transitLeg, isFalse);
    });

    test('PlanTransitLeg typename → transit leg', () {
      final json = {
        '__typename': 'PlanTransitLeg',
        'start': 37200,
        'end': 41400,
        'duration': 4200,
        'from': {
          'departure': 37200,
          'arrival': null,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Stop A'},
        },
        'to': {
          'departure': null,
          'arrival': 41400,
          'node': {'lat': 50.9, 'lon': 4.4, 'name': 'Stop B'},
        },
        'trip': {
          'headsign': 'North',
          'route': {'shortName': '1', 'longName': 'Line 1', 'mode': 'BUS'},
        },
        'previousDepartures': <dynamic>[],
        'nextDepartures': <dynamic>[],
      };
      final leg = parseMaasLeg(json, queryDate);
      expect(leg.transitLeg, isTrue);
    });

    test('unknown typename falls back to walk', () {
      final json = {
        '__typename': 'PlanUnknownLeg',
        'start': 36000,
        'end': 37200,
        'duration': 1200,
        'from': {
          'departure': 36000,
          'arrival': null,
          'node': {'lat': 50.8, 'lon': 4.3, 'name': 'A'},
        },
        'to': {
          'departure': null,
          'arrival': 37200,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'B'},
        },
      };
      final leg = parseMaasLeg(json, queryDate);
      expect(leg.transitLeg, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // parseMaasPlan
  // ---------------------------------------------------------------------------
  group('parseMaasPlan', () {
    Map<String, dynamic> makeWalkLegJson(int start, int end, String from, String to) => {
          '__typename': 'PlanWalkLeg',
          'start': start,
          'end': end,
          'duration': end - start,
          'from': {
            'departure': start,
            'arrival': null,
            'node': {'lat': 50.8, 'lon': 4.3, 'name': from},
          },
          'to': {
            'departure': null,
            'arrival': end,
            'node': {'lat': 50.85, 'lon': 4.35, 'name': to},
          },
        };

    test('start and end contain the query date', () {
      final json = {
        'start': 36000,
        'end': 41400,
        'legs': [makeWalkLegJson(36000, 41400, 'A', 'B')],
      };
      final plan = parseMaasPlan(json, queryDate);
      expect(plan.start, contains('2024-01-15'));
      expect(plan.end, contains('2024-01-15'));
    });

    test('fromName comes from first leg from.name', () {
      final json = {
        'start': 36000,
        'end': 41400,
        'legs': [makeWalkLegJson(36000, 41400, 'My Origin', 'Dest')],
      };
      expect(parseMaasPlan(json, queryDate).fromName, 'My Origin');
    });

    test('toName comes from last leg to.name', () {
      final json = {
        'start': 36000,
        'end': 41400,
        'legs': [makeWalkLegJson(36000, 41400, 'Origin', 'My Dest')],
      };
      expect(parseMaasPlan(json, queryDate).toName, 'My Dest');
    });

    test('empty legs → default from/to names', () {
      final json = {'start': 36000, 'end': 41400, 'legs': <dynamic>[]};
      final plan = parseMaasPlan(json, queryDate);
      expect(plan.fromName, 'Unknown departure');
      expect(plan.toName, 'Unknown arrival');
    });

    test('legs list is populated', () {
      final json = {
        'start': 36000,
        'end': 41400,
        'legs': [makeWalkLegJson(36000, 41400, 'A', 'B')],
      };
      expect(parseMaasPlan(json, queryDate).legs, hasLength(1));
    });

    test('raw is Plan.parse-compatible (start, end, legs as list)', () {
      final json = {
        'start': 36000,
        'end': 41400,
        'legs': [makeWalkLegJson(36000, 41400, 'A', 'B')],
      };
      final raw = parseMaasPlan(json, queryDate).raw;
      expect(raw['start'], isA<String>());
      expect(raw['end'], isA<String>());
      expect(raw['legs'], isA<List>());
    });

    // Helpers for trivial-walk filtering tests.
    Map<String, dynamic> makeTrivialWalkJson({
      int start = 36000,
      int durationSecs = 3,
    }) {
      final end = start + durationSecs;
      return {
        '__typename': 'PlanWalkLeg',
        'start': start,
        'end': end,
        'duration': durationSecs,
        'length': (durationSecs * 1.2).round(), // metres = secs × 1.2 m/s
        'from': {
          'departure': start,
          'arrival': null,
          'node': {'lat': 50.8, 'lon': 4.3, 'name': null}, // OSM node — no name
        },
        'to': {
          'departure': null,
          'arrival': end,
          'node': {'lat': 50.85, 'lon': 4.35, 'name': 'Gare du Nord'},
        },
      };
    }

    Map<String, dynamic> makeMinimalTransitJson({
      int start = 36010,
      int end = 37800,
      String fromName = 'Gare du Nord',
      String toName = 'Bruxelles-Midi',
    }) => {
          '__typename': 'PlanTransitLeg',
          'start': start,
          'end': end,
          'duration': end - start,
          'length': 5000,
          'from': {
            'departure': start,
            'arrival': null,
            'node': {'lat': 50.85, 'lon': 4.35, 'name': fromName},
          },
          'to': {
            'departure': null,
            'arrival': end,
            'node': {'lat': 50.84, 'lon': 4.35, 'name': toName},
          },
          'trip': {
            'headsign': 'Direction',
            'route': {
              'shortName': '1',
              'longName': 'Line 1',
              'mode': 'SUBWAY',
              'color': null,
              'textColor': null,
            },
          },
          'previousDepartures': <dynamic>[],
          'nextDepartures': <dynamic>[],
        };

    test('trivial walk (< 60 s) at start is stripped', () {
      final json = {
        'start': 36000,
        'end': 37800,
        'legs': [makeTrivialWalkJson(), makeMinimalTransitJson()],
      };
      final plan = parseMaasPlan(json, queryDate);
      expect(plan.legs, hasLength(1));
      expect(plan.legs.first.transitLeg, isTrue);
    });

    test('trivial walk at end is stripped', () {
      final json = {
        'start': 36000,
        'end': 37803,
        'legs': [
          makeMinimalTransitJson(end: 37800),
          makeTrivialWalkJson(start: 37800),
        ],
      };
      final plan = parseMaasPlan(json, queryDate);
      expect(plan.legs, hasLength(1));
      expect(plan.legs.last.transitLeg, isTrue);
    });

    test('fromName uses transit stop name after trivial walk is stripped', () {
      final json = {
        'start': 36000,
        'end': 37800,
        'legs': [makeTrivialWalkJson(), makeMinimalTransitJson(fromName: 'Gare du Nord')],
      };
      expect(parseMaasPlan(json, queryDate).fromName, 'Gare du Nord');
    });

    test('walk of exactly 60 s is NOT stripped (at threshold)', () {
      final json = {
        'start': 36000,
        'end': 37800,
        'legs': [
          makeWalkLegJson(36000, 36060, 'My Street', 'Stop'),
          makeMinimalTransitJson(start: 36060),
        ],
      };
      final plan = parseMaasPlan(json, queryDate);
      expect(plan.legs, hasLength(2));
      expect(plan.legs.first.transitLeg, isFalse);
    });

    test('real walk (> 60 s) at start is preserved', () {
      final json = {
        'start': 36000,
        'end': 37800,
        'legs': [
          makeWalkLegJson(36000, 36300, 'My Street', 'Stop'), // 5 min walk
          makeMinimalTransitJson(start: 36300),
        ],
      };
      final plan = parseMaasPlan(json, queryDate);
      expect(plan.legs, hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // buildRawLeg
  // ---------------------------------------------------------------------------
  group('buildRawLeg', () {
    Leg makeSimpleLeg({bool transitLeg = false, String mode = 'WALK'}) {
      const from = Place(
        name: 'From',
        lat: 50.8,
        lon: 4.3,
        departure: DepartureArrival(scheduledTime: '2024-01-15T10:00:00.000'),
      );
      const to = Place(
        name: 'To',
        lat: 50.9,
        lon: 4.4,
        arrival: DepartureArrival(scheduledTime: '2024-01-15T11:00:00.000'),
      );
      return Leg(
        id: null,
        mode: mode,
        transitLeg: transitLeg,
        realTime: false,
        from: from,
        to: to,
        duration: 3600,
        distance: 0,
        interlineWithPreviousLeg: false,
        otherDepartures: const [],
      );
    }

    test('required Leg.parse fields are present and correctly typed', () {
      final raw = buildRawLeg(makeSimpleLeg());
      expect(raw['transitLeg'], isA<bool>());
      expect(raw['realTime'], isA<bool>());
      expect(raw['duration'], isA<num>());
      expect(raw['distance'], isA<num>());
      expect(raw['interlineWithPreviousLeg'], isA<bool>());
    });

    test('from / to are maps with name, lat, lon', () {
      final raw = buildRawLeg(makeSimpleLeg());
      expect((raw['from'] as Map)['name'], 'From');
      expect((raw['from'] as Map)['lat'], 50.8);
      expect((raw['to'] as Map)['name'], 'To');
      expect((raw['to'] as Map)['lon'], 4.4);
    });

    test('mode is preserved', () {
      expect(buildRawLeg(makeSimpleLeg(mode: 'WALK'))['mode'], 'WALK');
      expect(buildRawLeg(makeSimpleLeg(mode: 'BUS', transitLeg: true))['mode'], 'BUS');
    });

    test('route is null (no GTFS IDs in maas-rs)', () {
      expect(buildRawLeg(makeSimpleLeg())['route'], isNull);
    });

    test('trip is null when leg has no trip', () {
      expect(buildRawLeg(makeSimpleLeg())['trip'], isNull);
    });

    test('from departure is serialized when present', () {
      final raw = buildRawLeg(makeSimpleLeg());
      final fromMap = raw['from'] as Map<String, dynamic>;
      expect((fromMap['departure'] as Map?)!['scheduledTime'], isNotNull);
    });

    test('to arrival is serialized when present', () {
      final raw = buildRawLeg(makeSimpleLeg());
      final toMap = raw['to'] as Map<String, dynamic>;
      expect((toMap['arrival'] as Map?)!['scheduledTime'], isNotNull);
    });
  });
}
