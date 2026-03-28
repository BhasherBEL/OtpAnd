import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/utils.dart';

import 'helpers/test_factories.dart';

void main() {
  group('round', () {
    test('rounds to nearest integer', () {
      expect(round(3.5, 0), 4);
      expect(round(3.4, 0), 3);
      expect(round(3.0, 0), 3);
    });

    test('rounds to 1 decimal place', () {
      expect(round(3.14, 1), 3.1);
      expect(round(3.76, 1), 3.8);
    });

    test('rounds to nearest 10 (decimals = -1)', () {
      expect(round(45, -1), 50);
      expect(round(34, -1), 30);
      expect(round(100, -1), 100);
    });

    test('rounds to nearest 100 (decimals = -2)', () {
      expect(round(350, -2), 400);
      expect(round(249, -2), 200);
    });
  });

  group('displayDistance', () {
    test('under 100 m → rounds to nearest 10 m', () {
      expect(displayDistance(45), '50 m');
      expect(displayDistance(14), '10 m');
    });

    test('100–999 m → rounds to nearest 100 m', () {
      expect(displayDistance(450), '500 m');
      expect(displayDistance(150), '200 m');
    });

    test('1 000–9 999 m → km with 1 decimal', () {
      expect(displayDistance(1500), '1.5 km');
      expect(displayDistance(2300), '2.3 km');
    });

    test('≥ 10 000 m → km rounded to integer', () {
      expect(displayDistance(12000), '12 km');
      expect(displayDistance(10500), '11 km');
    });
  });

  group('displayDistanceShort', () {
    test('always shows km with 1 decimal', () {
      expect(displayDistanceShort(1500), '1.5 km');
      expect(displayDistanceShort(500), '0.5 km');
    });
  });

  group('displayTime', () {
    test('under 55 s → shows seconds rounded to 10', () {
      expect(displayTime(45), '50s');
      expect(displayTime(10), '10s');
    });

    test('55 s – 3 569 s → shows minutes', () {
      expect(displayTime(60), '1 min');
      expect(displayTime(300), '5 min');
      expect(displayTime(3540), '59 min');
    });

    test('≥ 3 570 s → shows hours and minutes', () {
      expect(displayTime(3600), '1 h 0 min');
      expect(displayTime(5400), '1 h 30 min');
      expect(displayTime(7200), '2 h 0 min');
    });
  });

  group('displayTimeShortVague', () {
    test('formats as HH:MMh', () {
      expect(displayTimeShortVague(0), '00:00h');
      expect(displayTimeShortVague(3600), '01:00h');
      expect(displayTimeShortVague(5400), '01:30h');
      expect(displayTimeShortVague(600), '00:10h');
    });
  });

  group('displayTimeShort', () {
    test('under 3 600 s → minutes, minimum 1', () {
      expect(displayTimeShort(300), '5');
      expect(displayTimeShort(20), '1'); // rounds to 0 min, then max(0,1)=1
    });

    test('exact multiple of 3 600 s → Xh', () {
      expect(displayTimeShort(3600), '1h');
      expect(displayTimeShort(7200), '2h');
    });

    test('hours + minutes → XhY', () {
      expect(displayTimeShort(5400), '1h30');
      expect(displayTimeShort(9000), '2h30');
    });
  });

  group('displayPreciseTime', () {
    test('1 second', () => expect(displayPreciseTime(1), '1 second'));
    test('< 60 s → X seconds', () => expect(displayPreciseTime(30), '30 seconds'));
    test('60–119 s → 1 minute', () => expect(displayPreciseTime(90), '1 minute'));
    test('≥ 120 s < 3 600 s → X minutes', () {
      expect(displayPreciseTime(120), '2 minutes');
      expect(displayPreciseTime(300), '5 minutes');
    });
    test('≥ 3 600 s → Xh Y', () {
      expect(displayPreciseTime(3600), '1 h 0');
      expect(displayPreciseTime(5400), '1 h 30');
    });
  });

  group('displayDistanceInTime', () {
    test('converts distance to walking time string', () {
      // 1110 m / 1.11 m/s ≈ 1000 s → displayTimeShort(1000) = '17' min
      final result = displayDistanceInTime(1110);
      expect(result, isA<String>());
      expect(result.isNotEmpty, true);
    });
  });

  group('getColorFromCode', () {
    test('null → null', () {
      expect(getColorFromCode(null), isNull);
    });

    test('hex string with # → Color', () {
      expect(getColorFromCode('#FF0000'), const Color(0xFFFF0000));
      expect(getColorFromCode('#000000'), const Color(0xFF000000));
    });

    test('hex string without # (6 chars) → Color with FF alpha', () {
      expect(getColorFromCode('FF0000'), const Color(0xFFFF0000));
      expect(getColorFromCode('00FF00'), const Color(0xFF00FF00));
    });

    test('non-string non-null non-int → null', () {
      expect(getColorFromCode(3.14), isNull);
    });
  });

  group('iconForMode', () {
    test('WALK → walk icon', () {
      expect(iconForMode('WALK'), Icons.directions_walk);
    });
    test('BICYCLE → bike icon', () {
      expect(iconForMode('BICYCLE'), Icons.directions_bike);
    });
    test('CAR → car icon', () {
      expect(iconForMode('CAR'), Icons.directions_car);
    });
    test('BUS → bus icon', () {
      expect(iconForMode('BUS'), Icons.directions_bus);
    });
    test('RAIL → subway icon', () {
      expect(iconForMode('RAIL'), Icons.subway);
    });
    test('SUBWAY → subway icon', () {
      expect(iconForMode('SUBWAY'), Icons.subway);
    });
    test('TRAM → tram icon', () {
      expect(iconForMode('TRAM'), Icons.tram);
    });
    test('FERRY → boat icon', () {
      expect(iconForMode('FERRY'), Icons.directions_boat);
    });
    test('unknown mode → trip_origin icon', () {
      expect(iconForMode('UNKNOWN'), Icons.trip_origin);
    });
  });

  group('colorForMode', () {
    test('WALK → green', () => expect(colorForMode('WALK'), Colors.green));
    test('BUS → blue', () => expect(colorForMode('BUS'), Colors.blue));
    test('SUBWAY → deepOrange', () {
      expect(colorForMode('SUBWAY'), Colors.deepOrange);
    });
    test('TRAM → purple', () => expect(colorForMode('TRAM'), Colors.purple));
    test('RAIL → teal', () => expect(colorForMode('RAIL'), Colors.teal));
    test('unknown → grey.shade400', () {
      expect(colorForMode('FERRY'), Colors.grey.shade400);
    });
  });

  group('capitalize', () {
    test('capitalizes first letter and lowercases rest', () {
      expect(capitalize('hello'), 'Hello');
      expect(capitalize('BUS'), 'Bus');
      expect(capitalize('walk'), 'Walk');
    });

    test('empty string → empty string', () {
      expect(capitalize(''), '');
    });
  });

  group('parseTime', () {
    test('null → null', () {
      expect(parseTime(null), isNull);
    });

    test('valid ISO → DateTime', () {
      final result = parseTime('2024-01-15T10:30:00');
      expect(result, isNotNull);
      expect(result, isA<DateTime>());
    });

    test('invalid string → null', () {
      expect(parseTime('not-a-date'), isNull);
    });
  });

  group('formatTime', () {
    test('null → null', () {
      expect(formatTime(null), isNull);
    });

    test('valid ISO → HH:mm string', () {
      final result = formatTime('2024-01-15T10:30:00');
      expect(result, isNotNull);
      // Can't test exact value because of timezone conversion, but format check:
      expect(result, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('invalid string → null', () {
      expect(formatTime('not-a-date'), isNull);
    });
  });

  group('legDescription', () {
    test('WALK → "Walk"', () {
      expect(legDescription(makeLeg(mode: 'WALK')), 'Walk');
    });

    test('BICYCLE → "Bike"', () {
      expect(legDescription(makeLeg(mode: 'BICYCLE')), 'Bike');
    });

    test('CAR → "Car"', () {
      expect(legDescription(makeLeg(mode: 'CAR')), 'Car');
    });

    test('BUS with route shortName', () {
      final route = makeRouteInfo(shortName: '42', mode: RouteMode.bus);
      expect(legDescription(makeLeg(mode: 'BUS', route: route)), 'Bus  42');
    });

    test('BUS without route', () {
      expect(legDescription(makeLeg(mode: 'BUS')), 'Bus ');
    });

    test('RAIL with route shortName', () {
      final route = makeRouteInfo(shortName: 'IC3', mode: RouteMode.rail);
      expect(legDescription(makeLeg(mode: 'RAIL', route: route)), 'Rail  IC3');
    });

    test('unknown mode with route', () {
      final route = makeRouteInfo(shortName: 'X');
      expect(legDescription(makeLeg(mode: 'OTHER', route: route)), 'Other X');
    });

    test('unknown mode without route', () {
      expect(legDescription(makeLeg(mode: 'OTHER')), 'Other');
    });
  });

  group('calculateDuration', () {
    test('< 1 hour → Xmin', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 10, 30);
      expect(calculateDuration(start, end), '30min');
    });

    test('≥ 1 hour → Xh Ymin', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 11, 30);
      expect(calculateDuration(start, end), '1h 30min');
    });

    test('exact hours → Xh 0min', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 12, 0);
      expect(calculateDuration(start, end), '2h 0min');
    });
  });

  group('calculateDurationFromString', () {
    test('null inputs → 0', () {
      expect(calculateDurationFromString(null, null), 0);
      expect(calculateDurationFromString('2024-01-01T10:00:00', null), 0);
      expect(calculateDurationFromString(null, '2024-01-01T10:00:00'), 0);
    });

    test('valid ISO strings → seconds difference', () {
      final result = calculateDurationFromString(
        '2024-01-01T10:00:00.000',
        '2024-01-01T10:30:00.000',
      );
      expect(result, 1800);
    });

    test('invalid strings → 0', () {
      expect(calculateDurationFromString('invalid', 'also-invalid'), 0);
    });
  });
}
