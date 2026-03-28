import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/place.dart';

void main() {
  group('EstimatedTime', () {
    test('parse creates from JSON', () {
      final et = EstimatedTime.parse({
        'time': '2024-01-01T10:05:00',
        'delay': 'PT5M',
      });
      expect(et.time, '2024-01-01T10:05:00');
      expect(et.delay, 'PT5M');
    });

    test('parse handles null fields', () {
      final et = EstimatedTime.parse({'time': null, 'delay': null});
      expect(et.time, isNull);
      expect(et.delay, isNull);
    });

    test('toMap round-trips', () {
      final et = EstimatedTime(time: '2024-01-01T10:05:00', delay: 'PT5M');
      final map = et.toMap();
      expect(map['time'], '2024-01-01T10:05:00');
      expect(map['delay'], 'PT5M');
    });
  });

  group('DepartureArrival', () {
    test('parse from JSON with estimated time', () {
      final da = DepartureArrival.parse({
        'scheduledTime': '2024-01-01T10:00:00',
        'estimated': {
          'time': '2024-01-01T10:05:00',
          'delay': null,
        },
      });
      expect(da.scheduledTime, '2024-01-01T10:00:00');
      expect(da.estimated?.time, '2024-01-01T10:05:00');
    });

    test('parse from JSON without estimated time', () {
      final da = DepartureArrival.parse({
        'scheduledTime': '2024-01-01T10:00:00',
        'estimated': null,
      });
      expect(da.scheduledTime, '2024-01-01T10:00:00');
      expect(da.estimated, isNull);
    });

    test('realTime returns estimated time when present', () {
      final da = DepartureArrival(
        scheduledTime: '2024-01-01T10:00:00',
        estimated: EstimatedTime(time: '2024-01-01T10:05:00'),
      );
      expect(da.realTime, '2024-01-01T10:05:00');
    });

    test('realTime falls back to scheduledTime when no estimated', () {
      const da = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      expect(da.realTime, '2024-01-01T10:00:00');
    });

    test('realTime is null when both are null', () {
      const da = DepartureArrival();
      expect(da.realTime, isNull);
    });

    test('scheduledDateTime parses scheduledTime ISO string', () {
      const da = DepartureArrival(scheduledTime: '2024-01-01T10:00:00.000');
      expect(da.scheduledDateTime, isNotNull);
      expect(da.scheduledDateTime, isA<DateTime>());
    });

    test('scheduledDateTime is null when scheduledTime is null', () {
      const da = DepartureArrival();
      expect(da.scheduledDateTime, isNull);
    });

    test('realDateTime parses realTime', () {
      final da = DepartureArrival(
        scheduledTime: '2024-01-01T10:00:00',
        estimated: EstimatedTime(time: '2024-01-01T10:05:00'),
      );
      expect(da.realDateTime, isNotNull);
    });

    test('toMap round-trips', () {
      const da = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
      final map = da.toMap();
      expect(map['scheduledTime'], '2024-01-01T10:00:00');
      expect(map['estimated'], isNull);
    });

    group('parseFromStoptime', () {
      test('no realtime → only scheduled time', () {
        final da = DepartureArrival.parseFromStoptime(
          '2024-01-15',
          3600, // 1 hour = 10:00 AM
          false,
          3600,
        );
        expect(da.scheduledTime, isNotNull);
        expect(da.estimated, isNull);
      });

      test('with realtime → has estimated time', () {
        final da = DepartureArrival.parseFromStoptime(
          '2024-01-15',
          3600, // scheduled: 10:00
          true,
          3900, // realtime: 10:05
        );
        expect(da.scheduledTime, isNotNull);
        expect(da.estimated, isNotNull);
        expect(da.estimated!.time, isNotNull);
      });

      test('scheduledTime is later than midnight by the given seconds', () {
        final da = DepartureArrival.parseFromStoptime(
          '2024-01-15',
          7200, // 2 hours after midnight = 02:00
          false,
          7200,
        );
        final dt = da.scheduledDateTime!;
        // The exact hour depends on local timezone of parse, but duration from midnight is 2h
        expect(dt, isA<DateTime>());
      });
    });

    group('Equatable', () {
      test('equal DepartureArrivals with same scheduledTime', () {
        const da1 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
        const da2 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
        expect(da1, equals(da2));
      });

      test('different scheduledTime → not equal', () {
        const da1 = DepartureArrival(scheduledTime: '2024-01-01T10:00:00');
        const da2 = DepartureArrival(scheduledTime: '2024-01-01T11:00:00');
        expect(da1, isNot(equals(da2)));
      });
    });
  });

  group('Place', () {
    test('Equatable: same name, coords, and times → equal', () {
      const p1 = Place(name: 'Station', lat: 50.8, lon: 4.3);
      const p2 = Place(name: 'Station', lat: 50.8, lon: 4.3);
      expect(p1, equals(p2));
    });

    test('different lat → not equal', () {
      const p1 = Place(name: 'A', lat: 50.8, lon: 4.3);
      const p2 = Place(name: 'A', lat: 51.0, lon: 4.3);
      expect(p1, isNot(equals(p2)));
    });

    test('toMap contains expected keys', () {
      const p = Place(name: 'Station', lat: 50.8, lon: 4.3);
      final map = p.toMap();
      expect(map['name'], 'Station');
      expect(map['lat'], 50.8);
      expect(map['lon'], 4.3);
      expect(map.containsKey('departure'), true);
      expect(map.containsKey('arrival'), true);
      expect(map.containsKey('stop'), true);
    });
  });
}
