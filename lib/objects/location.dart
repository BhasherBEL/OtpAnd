import 'package:otpand/objects/stop.dart';

class Location {
  final String name;
  final String displayName;
  final double lat;
  final double lon;
  final Stop? stop;

  Location({
    required this.name,
    required this.displayName,
    required this.lat,
    required this.lon,
    this.stop,
  });

  static Location parse(Map<String, dynamic> locationJson) {
    return Location(
      name: locationJson['name'] as String? ?? 'Unknown',
      displayName: locationJson['name'] as String? ?? 'Unknown',
      lat: double.parse((locationJson['lat'] as String?) ?? '0.0'),
      lon: double.parse((locationJson['lon'] as String?) ?? '0.0'),
    );
  }
}
