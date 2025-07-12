import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/utils/maps.dart';

class Plan {
  final String? start;
  final String? end;
  final List<Leg> legs;

  Plan({required this.start, required this.end, required this.legs});

  Plan copyWith({
    String? start,
    String? end,
    List<Leg>? legs,
  }) {
    return Plan(
      start: start ?? this.start,
      end: end ?? this.end,
      legs: legs ?? this.legs,
    );
  }

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

  int getDuration() {
    if (legs.isEmpty) return 0;
    final firstDeparture = legs.first.from.departure?.scheduledDateTime;
    final lastArrival = legs.last.to.arrival?.scheduledDateTime;
    if (firstDeparture == null || lastArrival == null) return 0;
    return lastArrival.difference(firstDeparture).inSeconds;
  }

  double getEmissions() {
    return legs.fold(0, (prev, leg) => prev + leg.getEmissions());
  }

  double getFlightDistance() {
    return calculateDistance(
      legs.first.from.lat,
      legs.first.from.lon,
      legs.last.to.lat,
      legs.last.to.lon,
    );
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other.runtimeType != runtimeType) return false;
    final Plan otherPlan = other as Plan;
    if (start != otherPlan.start || end != otherPlan.end) return false;
    if (legs.length != otherPlan.legs.length) return false;
    for (int i = 0; i < legs.length; i++) {
      if (legs[i] != otherPlan.legs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        start,
        end,
        legs.map((leg) => leg.hashCode).reduce((a, b) => a ^ b),
      );
}
