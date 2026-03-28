import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/utils/maps.dart';

void main() {
  group('calculateDistance', () {
    test('same point → 0 m', () {
      final d = calculateDistance(50.0, 4.0, 50.0, 4.0);
      expect(d, closeTo(0.0, 0.001));
    });

    test('known distance: Brussels to Liège ≈ 90 km straight line', () {
      // Brussels: 50.8503°N, 4.3517°E
      // Liège: 50.6326°N, 5.5797°E
      final d = calculateDistance(50.8503, 4.3517, 50.6326, 5.5797);
      expect(d, closeTo(89700, 1000)); // within 1 km tolerance
    });

    test('known distance: Brussels to Antwerp ≈ 41 km straight line', () {
      // Brussels: 50.8503°N, 4.3517°E
      // Antwerp: 51.2194°N, 4.4025°E
      final d = calculateDistance(50.8503, 4.3517, 51.2194, 4.4025);
      expect(d, closeTo(41000, 1000)); // within 1 km tolerance
    });

    test('result is symmetric', () {
      final d1 = calculateDistance(50.0, 4.0, 51.0, 5.0);
      final d2 = calculateDistance(51.0, 5.0, 50.0, 4.0);
      expect(d1, closeTo(d2, 0.001));
    });

    test('distance is positive for different points', () {
      final d = calculateDistance(50.0, 4.0, 51.0, 5.0);
      expect(d, greaterThan(0));
    });
  });

  group('PolylineExt.unpackPolyline', () {
    test('converts list of [lat, lon] pairs to LatLng', () {
      final packed = [
        [50.8, 4.3],
        [50.9, 4.4],
        [51.0, 4.5],
      ];
      final points = packed.unpackPolyline();
      expect(points.length, 3);
      expect(points[0].latitude, 50.8);
      expect(points[0].longitude, 4.3);
      expect(points[1].latitude, 50.9);
      expect(points[2].latitude, 51.0);
    });

    test('empty list → empty list', () {
      final points = <List<num>>[].unpackPolyline();
      expect(points, isEmpty);
    });

    test('converts num types to double', () {
      final packed = [
        [50, 4],
      ];
      final points = packed.unpackPolyline();
      expect(points[0].latitude, 50.0);
      expect(points[0].longitude, 4.0);
    });
  });
}
