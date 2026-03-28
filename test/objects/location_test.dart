import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/location.dart';

void main() {
  group('Location', () {
    test('constructor stores all fields', () {
      final loc = Location(
        name: 'Brussels',
        displayName: 'Brussels, Belgium',
        lat: 50.8503,
        lon: 4.3517,
      );
      expect(loc.name, 'Brussels');
      expect(loc.displayName, 'Brussels, Belgium');
      expect(loc.lat, 50.8503);
      expect(loc.lon, 4.3517);
      expect(loc.stop, isNull);
    });

    group('parse', () {
      test('parses name, lat, lon from JSON strings', () {
        final loc = Location.parse({
          'name': 'Station',
          'lat': '50.8503',
          'lon': '4.3517',
        });
        expect(loc.name, 'Station');
        expect(loc.displayName, 'Station'); // same as name
        expect(loc.lat, closeTo(50.8503, 0.0001));
        expect(loc.lon, closeTo(4.3517, 0.0001));
      });

      test('null name → "Unknown"', () {
        final loc = Location.parse({
          'name': null,
          'lat': '50.0',
          'lon': '4.0',
        });
        expect(loc.name, 'Unknown');
        expect(loc.displayName, 'Unknown');
      });

      test('null lat/lon → 0.0', () {
        final loc = Location.parse({
          'name': 'Test',
          'lat': null,
          'lon': null,
        });
        expect(loc.lat, 0.0);
        expect(loc.lon, 0.0);
      });
    });
  });
}
