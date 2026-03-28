import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/stop.dart';

void main() {
  group('Stop', () {
    test('parse from JSON', () {
      final stop = Stop.parse({
        'gtfsId': 'agency:001',
        'name': 'Central Station',
        'platformCode': '3',
        'lat': 50.8503,
        'lon': 4.3517,
        'mode': 'RAIL',
      });
      expect(stop.gtfsId, 'agency:001');
      expect(stop.name, 'Central Station');
      expect(stop.platformCode, '3');
      expect(stop.lat, 50.8503);
      expect(stop.lon, 4.3517);
      expect(stop.mode, 'RAIL');
    });

    test('parse handles null platformCode and mode', () {
      final stop = Stop.parse({
        'gtfsId': 'agency:002',
        'name': 'Market',
        'platformCode': null,
        'lat': 50.0,
        'lon': 4.0,
        'mode': null,
      });
      expect(stop.platformCode, isNull);
      expect(stop.mode, isNull);
    });

    test('toMap round-trips fields', () {
      final stop = Stop(
        gtfsId: 'agency:001',
        name: 'Station',
        lat: 50.8,
        lon: 4.3,
        platformCode: '2A',
        mode: 'BUS',
      );
      final map = stop.toMap();
      expect(map['gtfsId'], 'agency:001');
      expect(map['name'], 'Station');
      expect(map['lat'], 50.8);
      expect(map['lon'], 4.3);
      expect(map['platformCode'], '2A');
      expect(map['mode'], 'BUS');
    });

    group('equality', () {
      test('same gtfsId → equal', () {
        final s1 = Stop(gtfsId: 'agency:1', name: 'A', lat: 1.0, lon: 2.0);
        final s2 = Stop(gtfsId: 'agency:1', name: 'B', lat: 3.0, lon: 4.0);
        expect(s1, equals(s2));
      });

      test('different gtfsId → not equal', () {
        final s1 = Stop(gtfsId: 'agency:1', name: 'A', lat: 1.0, lon: 2.0);
        final s2 = Stop(gtfsId: 'agency:2', name: 'A', lat: 1.0, lon: 2.0);
        expect(s1, isNot(equals(s2)));
      });

      test('hashCode is based on gtfsId', () {
        final s1 = Stop(gtfsId: 'agency:1', name: 'A', lat: 1.0, lon: 2.0);
        final s2 = Stop(gtfsId: 'agency:1', name: 'B', lat: 9.0, lon: 9.0);
        expect(s1.hashCode, equals(s2.hashCode));
      });
    });

    test('parseAll converts list', () {
      final stops = Stop.parseAll([
        {'gtfsId': 'a:1', 'name': 'S1', 'lat': 50.0, 'lon': 4.0, 'platformCode': null, 'mode': null},
        {'gtfsId': 'a:2', 'name': 'S2', 'lat': 51.0, 'lon': 5.0, 'platformCode': null, 'mode': null},
      ]);
      expect(stops.length, 2);
      expect(stops[0].gtfsId, 'a:1');
      expect(stops[1].gtfsId, 'a:2');
    });

    test('can be used as Map key (hashable)', () {
      final stop = Stop(gtfsId: 'agency:1', name: 'Test', lat: 50.0, lon: 4.0);
      final map = {stop: 'value'};
      expect(map[stop], 'value');
    });
  });
}
