import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/place.dart';
import 'package:otpand/objects/timed_stop.dart';

import '../helpers/test_factories.dart';

void main() {
  group('Leg.getEmissions', () {
    test('WALK: 0.016 kg CO₂/km', () {
      final leg = makeLeg(mode: 'WALK', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.016, 0.0001));
    });

    test('BICYCLE: 0.021 kg CO₂/km', () {
      final leg = makeLeg(mode: 'BICYCLE', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.021, 0.0001));
    });

    test('CAR: 0.271 kg CO₂/km', () {
      final leg = makeLeg(mode: 'CAR', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.271, 0.0001));
    });

    test('BUS: 0.101 kg CO₂/km', () {
      final leg = makeLeg(mode: 'BUS', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.101, 0.0001));
    });

    test('RAIL: 0.031 kg CO₂/km', () {
      final leg = makeLeg(mode: 'RAIL', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.031, 0.0001));
    });

    test('TRAIN: 0.031 kg CO₂/km', () {
      final leg = makeLeg(mode: 'TRAIN', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.031, 0.0001));
    });

    test('TRAM: 0.031 kg CO₂/km', () {
      final leg = makeLeg(mode: 'TRAM', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.031, 0.0001));
    });

    test('SUBWAY: 0.031 kg CO₂/km', () {
      final leg = makeLeg(mode: 'SUBWAY', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.031, 0.0001));
    });

    test('METRO: 0.031 kg CO₂/km', () {
      final leg = makeLeg(mode: 'METRO', distance: 1000);
      expect(leg.getEmissions(), closeTo(0.031, 0.0001));
    });

    test('unknown mode: 0 emissions', () {
      final leg = makeLeg(mode: 'HELICOPTER', distance: 1000);
      expect(leg.getEmissions(), 0.0);
    });

    test('scales linearly with distance', () {
      final leg2km = makeLeg(mode: 'BUS', distance: 2000);
      expect(leg2km.getEmissions(), closeTo(0.202, 0.0001));
    });
  });

  group('Leg.color', () {
    test('route color takes priority', () {
      final route = makeRouteInfo(color: Colors.pink);
      final leg = makeLeg(mode: 'BUS', route: route);
      expect(leg.color, Colors.pink);
    });

    test('BUS without route → amber', () {
      expect(makeLeg(mode: 'BUS').color, Colors.amber);
    });

    test('RAIL without route → teal', () {
      expect(makeLeg(mode: 'RAIL').color, Colors.teal);
    });

    test('TRAIN without route → teal', () {
      expect(makeLeg(mode: 'TRAIN').color, Colors.teal);
    });

    test('TRAM without route → purple', () {
      expect(makeLeg(mode: 'TRAM').color, Colors.purple);
    });

    test('SUBWAY without route → deepOrange', () {
      expect(makeLeg(mode: 'SUBWAY').color, Colors.deepOrange);
    });

    test('METRO without route → deepOrange', () {
      expect(makeLeg(mode: 'METRO').color, Colors.deepOrange);
    });

    test('FERRY without route → lightBlue', () {
      expect(makeLeg(mode: 'FERRY').color, Colors.lightBlue);
    });

    test('WALK without route → grey.shade400', () {
      expect(makeLeg(mode: 'WALK').color, Colors.grey.shade400);
    });
  });

  group('Leg.lineColor', () {
    test('route color takes priority', () {
      final route = makeRouteInfo(color: Colors.indigo);
      final leg = makeLeg(mode: 'BUS', route: route);
      expect(leg.lineColor, Colors.indigo);
    });

    test('WALK → black', () {
      expect(makeLeg(mode: 'WALK').lineColor, Colors.black);
    });

    test('CAR → black', () {
      expect(makeLeg(mode: 'CAR').lineColor, Colors.black);
    });

    test('BICYCLE → black', () {
      expect(makeLeg(mode: 'BICYCLE').lineColor, Colors.black);
    });

    test('BUS without route → amber', () {
      expect(makeLeg(mode: 'BUS').lineColor, Colors.amber);
    });

    test('TRAM without route → purple', () {
      expect(makeLeg(mode: 'TRAM').lineColor, Colors.purple);
    });
  });

  group('Leg.intermediateStops', () {
    final stopA = makeStop(gtfsId: 'a:stop1', name: 'Stop A');
    final stopB = makeStop(gtfsId: 'a:stop2', name: 'Stop B');
    final stopC = makeStop(gtfsId: 'a:stop3', name: 'Stop C');
    final stopD = makeStop(gtfsId: 'a:stop4', name: 'Stop D');

    test('returns [] when tripStops is null', () {
      final leg = makeLeg(tripStops: null);
      expect(leg.intermediateStops, isEmpty);
    });

    test('returns [] when from.stop is null', () {
      final leg = makeLeg(
        from: makePlace(stop: null),
        to: makePlace(stop: stopD),
        tripStops: [makeTimedStop(stop: stopA)],
      );
      expect(leg.intermediateStops, isEmpty);
    });

    test('returns [] when to.stop is null', () {
      final leg = makeLeg(
        from: makePlace(stop: stopA),
        to: makePlace(stop: null),
        tripStops: [makeTimedStop(stop: stopA)],
      );
      expect(leg.intermediateStops, isEmpty);
    });

    test('returns stops between from and to', () {
      final timedA = makeTimedStop(stop: stopA);
      final timedB = makeTimedStop(stop: stopB);
      final timedC = makeTimedStop(stop: stopC);
      final timedD = makeTimedStop(stop: stopD);

      final leg = makeLeg(
        from: makePlace(stop: stopA),
        to: makePlace(stop: stopD),
        tripStops: [timedA, timedB, timedC, timedD],
      );

      final intermediate = leg.intermediateStops;
      expect(intermediate.length, 2);
      expect(intermediate[0].stop, stopB);
      expect(intermediate[1].stop, stopC);
    });

    test('returns [] when from and to are adjacent', () {
      final timedA = makeTimedStop(stop: stopA);
      final timedB = makeTimedStop(stop: stopB);

      final leg = makeLeg(
        from: makePlace(stop: stopA),
        to: makePlace(stop: stopB),
        tripStops: [timedA, timedB],
      );

      expect(leg.intermediateStops, isEmpty);
    });

    test('returns [] when from stop is not found in tripStops', () {
      final timedB = makeTimedStop(stop: stopB);
      final timedC = makeTimedStop(stop: stopC);

      final leg = makeLeg(
        from: makePlace(stop: stopA), // not in tripStops
        to: makePlace(stop: stopC),
        tripStops: [timedB, timedC],
      );

      expect(leg.intermediateStops, isEmpty);
    });
  });

  group('Leg.frequency', () {
    test('null when fewer than 2 other departures', () {
      final leg = makeLeg(otherDepartures: []);
      expect(leg.frequency, isNull);
    });

    test('null when from.departure is null', () {
      final leg = makeLeg(
        from: makePlace(departure: null),
        otherDepartures: [makeLeg(), makeLeg()],
      );
      expect(leg.frequency, isNull);
    });

    test('returns consistent interval in minutes', () {
      // Main departure at 10:00, others at 10:10 and 10:20 → freq = 10 min
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      const dep20 = DepartureArrival(scheduledTime: '2024-01-01T10:20:00');

      final other1 = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:10:00')),
      );
      final other2 = makeLeg(
        from: makePlace(departure: dep20),
      );

      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [other1, other2],
      );

      expect(leg.frequency, 10);
    });

    test('returns null when intervals are inconsistent', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      const dep15 = DepartureArrival(scheduledTime: '2024-01-01T10:15:00');
      const dep25 = DepartureArrival(scheduledTime: '2024-01-01T10:25:00');

      // 10→15 = 5 min, 15→25 = 10 min → inconsistent
      final other1 = makeLeg(from: makePlace(departure: dep15));
      final other2 = makeLeg(from: makePlace(departure: dep25));

      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [other1, other2],
      );

      expect(leg.frequency, isNull);
    });
  });

  group('Leg.soonestNextDepartureLeg', () {
    test('returns null when no otherDepartures', () {
      final leg = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:00:00')),
      );
      expect(leg.soonestNextDepartureLeg, isNull);
    });

    test('returns null when from.departure has no scheduledTime', () {
      final other = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:10:00')),
      );
      final leg = makeLeg(
        from: makePlace(departure: null),
        otherDepartures: [other],
      );
      expect(leg.soonestNextDepartureLeg, isNull);
    });

    test('returns the leg with the nearest next departure', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final other5 = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:05:00')),
      );
      final other20 = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:20:00')),
      );
      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [other20, other5],
      );
      expect(leg.soonestNextDepartureLeg, same(other5));
    });

    test('ignores departures at or before current departure', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final earlier = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T09:50:00')),
      );
      final sameTime = makeLeg(from: makePlace(departure: dep10));
      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [earlier, sameTime],
      );
      expect(leg.soonestNextDepartureLeg, isNull);
    });

    test('ignores other legs with no departure scheduledTime', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final noTime = makeLeg(from: makePlace(departure: null));
      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [noTime],
      );
      expect(leg.soonestNextDepartureLeg, isNull);
    });
  });

  group('Leg.soonestNextDepartureWaitSecs', () {
    test('returns null when no otherDepartures', () {
      final leg = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:00:00')),
      );
      expect(leg.soonestNextDepartureWaitSecs, isNull);
    });

    test('returns null when from.departure has no scheduledTime', () {
      final other = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:10:00')),
      );
      final leg = makeLeg(
        from: makePlace(departure: null),
        otherDepartures: [other],
      );
      expect(leg.soonestNextDepartureWaitSecs, isNull);
    });

    test('returns seconds to nearest next departure', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final other5 = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:05:00')),
      );
      final other20 = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:20:00')),
      );
      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [other20, other5],
      );
      expect(leg.soonestNextDepartureWaitSecs, 5 * 60);
    });

    test('is consistent with soonestNextDepartureLeg', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final other5 = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:05:00')),
      );
      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [other5],
      );
      final soonestLeg = leg.soonestNextDepartureLeg!;
      final expectedWait = soonestLeg.from.departure!.scheduledDateTime!
          .difference(leg.from.departure!.scheduledDateTime!)
          .inSeconds;
      expect(leg.soonestNextDepartureWaitSecs, expectedWait);
    });

    test('ignores departures that are not after current departure', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final earlier = makeLeg(
        from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T09:50:00')),
      );
      final same = makeLeg(from: makePlace(departure: dep10));
      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [earlier, same],
      );
      expect(leg.soonestNextDepartureWaitSecs, isNull);
    });

    test('ignores other legs with no departure scheduledTime', () {
      const dep10 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final noTime = makeLeg(from: makePlace(departure: null));
      final leg = makeLeg(
        from: makePlace(departure: dep10),
        otherDepartures: [noTime],
      );
      expect(leg.soonestNextDepartureWaitSecs, isNull);
    });
  });

  group('Leg equality', () {
    test('same id → equal regardless of other fields', () {
      final l1 = makeLeg(id: 'leg-1', mode: 'WALK', distance: 100);
      final l2 = makeLeg(id: 'leg-1', mode: 'BUS', distance: 999);
      expect(l1, equals(l2));
    });

    test('null id → uses field-based equality', () {
      final l1 = makeLeg(id: null, mode: 'WALK', distance: 100, duration: 60);
      final l2 = makeLeg(id: null, mode: 'WALK', distance: 100, duration: 60);
      expect(l1, equals(l2));
    });

    test('null id → different mode → not equal', () {
      final l1 = makeLeg(id: null, mode: 'WALK');
      final l2 = makeLeg(id: null, mode: 'BUS');
      expect(l1, isNot(equals(l2)));
    });
  });

  group('Leg.toMap', () {
    test('contains expected keys', () {
      final leg = makeLeg(mode: 'WALK', duration: 120, distance: 200);
      final map = leg.toMap();
      expect(map['mode'], 'WALK');
      expect(map['duration'], 120);
      expect(map['distance'], 200);
      expect(map['transitLeg'], false);
      expect(map['realTime'], false);
      expect(map.containsKey('from'), true);
      expect(map.containsKey('to'), true);
    });
  });
}
