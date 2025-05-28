import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/timedStop.dart';
import 'package:otpand/objects/trip.dart';
import 'package:otpand/utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:otpand/utils/gnss.dart';
import 'package:otpand/utils/maps.dart';

class Plan {
  final String start;
  final String end;
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
}

class Leg {
  final String? id;
  final String mode;
  final String? headsign;
  final bool transitLeg;
  final bool realTime;
  final Place from;
  final Place to;
  final RouteInfo? route;
  final num duration;
  final num distance;
  final List<TimedStop>? tripStops;
  final bool interlineWithPreviousLeg;
  final List<DepartureArrival> otherDepartures;
  final Trip? trip;
  final String? serviceDate;
  final String? geometry;

  Leg({
    required this.id,
    required this.mode,
    this.headsign,
    required this.transitLeg,
    required this.realTime,
    required this.from,
    required this.to,
    this.route,
    required this.duration,
    required this.distance,
    this.tripStops,
    required this.interlineWithPreviousLeg,
    required this.otherDepartures,
    this.trip,
    this.serviceDate,
    this.geometry,
  });

  get color {
    if (route?.color != null) return route!.color;
    if (mode == "WALK") return Colors.grey.shade300;
    if (mode == "BUS") return Colors.amber.shade600;
    if (mode == "RAIL" || mode == "TRAIN") {
      return Colors.lightBlue.shade300;
    }
    return Colors.grey.shade400;
  }

  get otherDeparturesText {
    if (otherDepartures.isEmpty) return "";
    if (otherDepartures.length == 1) {
      return formatTime(otherDepartures[0].realTime);
    } else {
      return "${otherDepartures.sublist(0, otherDepartures.length - 1).map((e) {
        return formatTime(e.realTime);
      }).join(", ")} and ${formatTime(otherDepartures.last.realTime)}";
    }
  }

  List<TimedStop> get intermediateStops {
    if (tripStops == null || from.stop == null || to.stop == null) {
      return [];
    }

    bool inBetween = false;
    List<TimedStop> intermediateStops = [];

    for (final timedStop in tripStops!) {
      if (timedStop.stop == from.stop) {
        inBetween = true;
      } else if (timedStop.stop == to.stop) {
        return intermediateStops;
      } else if (inBetween) {
        intermediateStops.add(timedStop);
      }
    }
    return [];
  }

  Polyline get polyline {
    if (geometry == null) {
      return Polyline(
        points: [LatLng(from.lat, from.lon), LatLng(to.lat, to.lon)],
        color: color,
        strokeWidth: 8.0,
      );
    }

    final points = decodePolyline(geometry!).unpackPolyline();

    return Polyline(
      points: points,
      color: route?.color ?? route?.mode.color ?? color,
      strokeWidth: 4.0,
    );
  }

  LatLng get midPoint {
    final distance = Distance();

    if (geometry == null) {
      return LatLng((from.lat + to.lat) / 2, (from.lon + to.lon) / 2);
    }

    final points = decodePolyline(geometry!).unpackPolyline();
    double totalDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distance(points[i], points[i + 1]);
    }

    double middleDistance = totalDistance / 2;
    double currentDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      final newDist = distance(points[i], points[i + 1]);
      if (currentDistance + newDist < middleDistance) {
        currentDistance += newDist;
        continue;
      }

      final ratio = (middleDistance - currentDistance) / newDist;

      return LatLng(
        points[i].latitude +
            ratio * (points[i + 1].latitude - points[i].latitude),
        points[i].longitude +
            ratio * (points[i + 1].longitude - points[i].longitude),
      );
    }

    return LatLng((from.lat + to.lat) / 2, (from.lon + to.lon) / 2);
  }
}

class Place {
  final String name;
  final double lat;
  final double lon;
  final DepartureArrival? departure;
  final DepartureArrival? arrival;
  final Stop? stop;

  Place({
    required this.name,
    required this.lat,
    required this.lon,
    this.departure,
    this.arrival,
    this.stop,
  });
}

class DepartureArrival {
  final String? scheduledTime;
  final EstimatedTime? estimated;

  DepartureArrival({this.scheduledTime, this.estimated});

  static DepartureArrival parse(Map<String, dynamic> json) {
    return DepartureArrival(
      scheduledTime: json['scheduledTime'] as String?,
      estimated:
          json['estimated'] != null
              ? EstimatedTime.parse(json['estimated'] as Map<String, dynamic>)
              : null,
    );
  }

  static DepartureArrival parseFromStoptime(
    String serviceDate,
    int scheduledTime,
    bool realtime,
    int realtimeTime,
  ) {
    final year = int.parse(serviceDate.substring(0, 4));
    final month = int.parse(serviceDate.substring(5, 7));
    final day = int.parse(serviceDate.substring(8, 10));
    final midnight = DateTime(year, month, day);

    final scheduledDateTime = midnight.add(Duration(seconds: scheduledTime));
    final scheduledIso = scheduledDateTime.toIso8601String();

    EstimatedTime? estimated;
    if (realtime) {
      final realtimeDateTime = midnight.add(Duration(seconds: realtimeTime));
      final realtimeIso = realtimeDateTime.toIso8601String();
      estimated = EstimatedTime(time: realtimeIso);
    }

    return DepartureArrival(scheduledTime: scheduledIso, estimated: estimated);
  }

  get realTime {
    if (estimated != null && estimated!.time != null) {
      return estimated!.time;
    } else {
      return scheduledTime;
    }
  }
}

class EstimatedTime {
  final String? time;
  final String? delay;

  EstimatedTime({this.time, this.delay});

  static EstimatedTime parse(Map<String, dynamic> json) {
    return EstimatedTime(
      time: json['time'] as String?,
      delay: json['delay'] as String?,
    );
  }
}

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
}
