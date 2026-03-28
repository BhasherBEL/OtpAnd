import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/objects/place.dart';

import '../helpers/test_factories.dart';

void main() {
  group('Plan', () {
    group('copyWith', () {
      test('returns new plan with updated fields', () {
        final plan = makePlan(fromName: 'Origin', toName: 'Destination');
        final copy = plan.copyWith(fromName: 'NewOrigin');
        expect(copy.fromName, 'NewOrigin');
        expect(copy.toName, 'Destination'); // unchanged
      });

      test('preserves id when not specified', () {
        final plan = makePlan(id: 42);
        final copy = plan.copyWith(fromName: 'New');
        expect(copy.id, 42);
      });

      test('can update id', () {
        final plan = makePlan(id: null);
        final copy = plan.copyWith(id: 10);
        expect(copy.id, 10);
      });
    });

    group('copyWithoutId', () {
      test('removes id from plan', () {
        final plan = makePlan(id: 5);
        final copy = plan.copyWithoutId();
        expect(copy.id, isNull);
        expect(copy.fromName, plan.fromName);
        expect(copy.start, plan.start);
      });
    });

    group('startDateTime / endDateTime', () {
      test('parses start ISO string to DateTime', () {
        final plan = makePlan(start: '2024-06-15T10:30:00');
        expect(plan.startDateTime, isA<DateTime>());
      });

      test('parses end ISO string to DateTime', () {
        final plan = makePlan(end: '2024-06-15T11:45:00');
        expect(plan.endDateTime, isA<DateTime>());
      });
    });

    group('getDuration', () {
      test('returns 0 when legs is empty', () {
        final plan = makePlan(legs: []);
        expect(plan.getDuration(), 0);
      });

      test('returns 0 when first leg has no departure', () {
        final leg = makeLeg(from: makePlace(departure: null));
        final plan = makePlan(legs: [leg]);
        expect(plan.getDuration(), 0);
      });

      test('returns 0 when last leg has no arrival', () {
        final leg = makeLeg(
          from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T10:00:00')),
          to: makePlace(arrival: null),
        );
        final plan = makePlan(legs: [leg]);
        expect(plan.getDuration(), 0);
      });

      test('returns duration in seconds between first departure and last arrival', () {
        final leg = makeLeg(
          from: makePlace(
            departure: const DepartureArrival(scheduledTime: '2024-01-01T10:00:00.000'),
          ),
          to: makePlace(
            arrival: const DepartureArrival(scheduledTime: '2024-01-01T11:00:00.000'),
          ),
        );
        final plan = makePlan(legs: [leg]);
        expect(plan.getDuration(), 3600);
      });

      test('uses first leg departure and last leg arrival with multi-leg plan', () {
        final leg1 = makeLeg(
          from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T09:00:00.000')),
          to: makePlace(arrival: const DepartureArrival(scheduledTime: '2024-01-01T09:30:00.000')),
        );
        final leg2 = makeLeg(
          from: makePlace(departure: const DepartureArrival(scheduledTime: '2024-01-01T09:35:00.000')),
          to: makePlace(arrival: const DepartureArrival(scheduledTime: '2024-01-01T10:00:00.000')),
        );
        final plan = makePlan(legs: [leg1, leg2]);
        expect(plan.getDuration(), 3600);
      });
    });

    group('getEmissions', () {
      test('returns 0 for empty legs', () {
        final plan = makePlan(legs: []);
        expect(plan.getEmissions(), 0.0);
      });

      test('sums emissions from all legs', () {
        // Walk 1km = 0.016 kg, Bus 1km = 0.101 kg → total 0.117 kg
        final walkLeg = makeLeg(mode: 'WALK', distance: 1000);
        final busLeg = makeLeg(mode: 'BUS', distance: 1000);
        final plan = makePlan(legs: [walkLeg, busLeg]);
        expect(plan.getEmissions(), closeTo(0.117, 0.0001));
      });
    });

    group('getFlightDistance', () {
      test('returns positive distance for different coords', () {
        final leg = makeLeg(
          from: makePlace(lat: 50.8, lon: 4.3),
          to: makePlace(lat: 50.9, lon: 4.4),
        );
        final plan = makePlan(legs: [leg]);
        expect(plan.getFlightDistance(), greaterThan(0));
      });

      test('returns 0 for same coords', () {
        final leg = makeLeg(
          from: makePlace(lat: 50.8, lon: 4.3),
          to: makePlace(lat: 50.8, lon: 4.3),
        );
        final plan = makePlan(legs: [leg]);
        expect(plan.getFlightDistance(), closeTo(0, 0.001));
      });
    });

    group('getBounds', () {
      test('returns bounds covering all leg points', () {
        final leg = makeLeg(
          from: makePlace(lat: 50.0, lon: 4.0),
          to: makePlace(lat: 51.0, lon: 5.0),
        );
        final plan = makePlan(legs: [leg]);
        final bounds = plan.getBounds();
        expect(bounds.south, closeTo(50.0, 0.001));
        expect(bounds.north, closeTo(51.0, 0.001));
        expect(bounds.west, closeTo(4.0, 0.001));
        expect(bounds.east, closeTo(5.0, 0.001));
      });

      test('expands to cover multiple legs', () {
        final leg1 = makeLeg(
          from: makePlace(lat: 50.0, lon: 4.0),
          to: makePlace(lat: 50.5, lon: 4.5),
        );
        final leg2 = makeLeg(
          from: makePlace(lat: 50.5, lon: 4.5),
          to: makePlace(lat: 51.0, lon: 5.0),
        );
        final plan = makePlan(legs: [leg1, leg2]);
        final bounds = plan.getBounds();
        expect(bounds.south, closeTo(50.0, 0.001));
        expect(bounds.north, closeTo(51.0, 0.001));
        expect(bounds.west, closeTo(4.0, 0.001));
        expect(bounds.east, closeTo(5.0, 0.001));
      });
    });

    group('toMap', () {
      test('contains expected keys', () {
        final plan = makePlan(id: 3);
        final map = plan.toMap();
        expect(map['id'], 3);
        expect(map['start'], isA<String>());
        expect(map['end'], isA<String>());
        expect(map['fromName'], isA<String>());
        expect(map['toName'], isA<String>());
        expect(map['legs'], isA<List>());
      });
    });

    group('equality', () {
      test('identical plans are equal', () {
        final leg = makeLeg(id: 'l1', mode: 'WALK');
        final p1 = makePlan(start: '2024-01-01T10:00:00', end: '2024-01-01T11:00:00', legs: [leg]);
        final p2 = makePlan(start: '2024-01-01T10:00:00', end: '2024-01-01T11:00:00', legs: [leg]);
        expect(p1, equals(p2));
      });

      test('different start → not equal', () {
        final leg = makeLeg(id: 'l1');
        final p1 = makePlan(start: '2024-01-01T10:00:00', legs: [leg]);
        final p2 = makePlan(start: '2024-01-01T11:00:00', legs: [leg]);
        expect(p1, isNot(equals(p2)));
      });

      test('different leg count → not equal', () {
        final p1 = makePlan(legs: [makeLeg(id: 'l1')]);
        final p2 = makePlan(legs: [makeLeg(id: 'l1'), makeLeg(id: 'l2')]);
        expect(p1, isNot(equals(p2)));
      });

      test('id is not part of equality', () {
        final leg = makeLeg(id: 'l1', mode: 'WALK');
        final p1 = makePlan(id: 1, legs: [leg]);
        final p2 = makePlan(id: 2, legs: [leg]);
        // Same start/end/legs → equal regardless of id
        expect(p1, equals(p2));
      });
    });
  });
}
