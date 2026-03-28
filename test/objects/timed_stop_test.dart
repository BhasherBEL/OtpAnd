import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/place.dart';
import 'package:otpand/objects/timed_stop.dart';

import '../helpers/test_factories.dart';

void main() {
  group('PickupDropoffType.fromString', () {
    test('null → null', () {
      expect(PickupDropoffType.fromString(null), isNull);
    });

    test('"SCHEDULED" → scheduled', () {
      expect(PickupDropoffType.fromString('SCHEDULED'), PickupDropoffType.scheduled);
    });

    test('"NONE" → none', () {
      expect(PickupDropoffType.fromString('NONE'), PickupDropoffType.none);
    });

    test('"COORDINATE_WITH_DRIVER" → coordinateWithDriver', () {
      expect(
        PickupDropoffType.fromString('COORDINATE_WITH_DRIVER'),
        PickupDropoffType.coordinateWithDriver,
      );
    });

    test('"CALL_AGENCY" → callAgency', () {
      expect(PickupDropoffType.fromString('CALL_AGENCY'), PickupDropoffType.callAgency);
    });

    test('unknown string → null', () {
      expect(PickupDropoffType.fromString('UNKNOWN'), isNull);
      expect(PickupDropoffType.fromString(''), isNull);
    });
  });

  group('TimedStop', () {
    test('constructor stores all fields', () {
      final stop = makeStop();
      final ts = makeTimedStop(stop: stop);
      expect(ts.stop, stop);
      expect(ts.arrival, isNotNull);
      expect(ts.departure, isNotNull);
    });

    test('isPast returns true for past departure', () {
      final ts = TimedStop(
        stop: makeStop(),
        arrival: const DepartureArrival(scheduledTime: '2020-01-01T10:00:00'),
        departure: const DepartureArrival(scheduledTime: '2020-01-01T10:00:30'),
      );
      expect(ts.isPast(), isTrue);
    });

    test('isPast returns false for future departure', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      final futureIso = future.toIso8601String();
      final ts = TimedStop(
        stop: makeStop(),
        arrival: DepartureArrival(scheduledTime: futureIso),
        departure: DepartureArrival(scheduledTime: futureIso),
      );
      expect(ts.isPast(), isFalse);
    });

    test('toMap contains stop and time data', () {
      final ts = makeTimedStop();
      final map = ts.toMap();
      expect(map.containsKey('stop'), true);
      expect(map.containsKey('arrival'), true);
      expect(map.containsKey('departure'), true);
    });
  });
}
