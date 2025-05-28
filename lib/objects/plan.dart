import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:otpand/objects/leg.dart';

class Plan {
  final String? start;
  final String? end;
  final List<Leg> legs;

  Plan({required this.start, required this.end, required this.legs});

  LatLngBounds getBounds() {
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (final leg in legs) {
      if (leg.from.lat < minLat) minLat = leg.from.lat;
      if (leg.from.lat > maxLat) maxLat = leg.from.lat;
      if (leg.from.lon < minLon) minLon = leg.from.lon;
      if (leg.from.lon > maxLon) maxLon = leg.from.lon;
      if (leg.to.lat < minLat) minLat = leg.to.lat;
      if (leg.to.lat > maxLat) maxLat = leg.to.lat;
      if (leg.to.lon < minLon) minLon = leg.to.lon;
      if (leg.to.lon > maxLon) maxLon = leg.to.lon;
    }

    return LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
  }

  static Future<Plan> parse(Map<String, dynamic> planJson) async {
    List<Leg> legs = [];

    for (final legJson in planJson['legs'] as Iterable) {
      legs.add(await Leg.parse(legJson as Map<String, dynamic>));
    }

    return Plan(
      start: planJson['start'] as String?,
      end: planJson['end'] as String?,
      legs: legs,
    );
  }

  static Future<List<Plan>> parseAll(
    List<Map<String, dynamic>> rawPlans,
  ) async {
    return await Future.wait(rawPlans.map((e) => parse(e)));
  }
}
