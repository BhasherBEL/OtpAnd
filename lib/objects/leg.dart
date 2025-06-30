import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/place.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/timed_stop.dart';
import 'package:otpand/objects/trip.dart';
import 'package:otpand/utils.dart';
import 'package:otpand/utils/maps.dart';

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
  final List<Leg> otherDepartures;
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

  Color get color {
    if (route?.color != null) return route!.color!;
    if (mode == 'BUS') return Colors.amber.shade600;
    if (mode == 'RAIL' || mode == 'TRAIN') {
      return Colors.lightBlue.shade300;
    }
    return Colors.grey.shade400;
  }

  Color get lineColor {
    if (route?.color != null) return route!.color!;
    if (mode == 'WALK' || mode == 'CAR' || mode == 'BICYCLE') {
      return Colors.black;
    }
    if (mode == 'BUS') return Colors.amber.shade600;
    if (mode == 'RAIL' || mode == 'TRAIN') {
      return Colors.lightBlue.shade300;
    }
    print(mode);
    return Colors.grey.shade400;
  }

  String? otherDeparturesText({bool short = false}) {
    if (otherDepartures.isEmpty) return '';
    if (otherDepartures.length == 1) {
      return formatTime(otherDepartures[0].from.departure?.realTime);
    } else if (short == false) {
      return "${otherDepartures.sublist(0, otherDepartures.length - 1).map((e) {
        return formatTime(e.from.departure?.realTime);
      }).join(", ")} and ${formatTime(otherDepartures.last.from.departure?.realTime)}";
    } else {
      return otherDepartures.map((e) {
        return formatTime(e.from.departure?.realTime);
      }).join(', ');
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
        color: lineColor,
        strokeWidth: 8.0,
      );
    }

    final points = decodePolyline(geometry!).unpackPolyline();

    return Polyline(
      points: points,
      color: route?.color ?? route?.mode.color ?? lineColor,
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

  static Future<Leg> parse(Map<String, dynamic> legJson) async {
    final route = legJson['route'] != null
        ? await RouteDao().get(legJson['route']['gtfsId'] as String)
        : null;

    List<TimedStop>? intermediate;

    if (legJson['serviceDate'] != null &&
        legJson['trip'] != null &&
        (legJson['trip'] as Map<String, dynamic>).containsKey('stoptimes')) {
      intermediate = [];
      for (final s in legJson['trip']['stoptimes'] as List) {
        final stop = await StopDao().get(s['stop']['gtfsId'] as String);
        if (stop != null) {
          intermediate.add(
            TimedStop(
              stop: stop,
              arrival: DepartureArrival.parseFromStoptime(
                legJson['serviceDate'] as String,
                s['scheduledArrival'] as int,
                s['realtime'] as bool,
                s['realtimeArrival'] as int,
              ),
              departure: DepartureArrival.parseFromStoptime(
                legJson['serviceDate'] as String,
                s['scheduledDeparture'] as int,
                s['realtime'] as bool,
                s['realtimeDeparture'] as int,
              ),
              dropoffType: PickupDropoffType.fromString(
                s['dropoffType'] as String?,
              ),
              pickupType: PickupDropoffType.fromString(
                s['pickupType'] as String?,
              ),
            ),
          );
        }
      }
    }

    final List<Leg> otherDepartures = [];
    if (legJson.containsKey('previousLegs') &&
        legJson['previousLegs'] != null) {
      for (final leg in legJson['previousLegs'] as Iterable) {
        if (leg == null) continue;
        otherDepartures.add(
          await Leg.parse(leg as Map<String, dynamic>),
        );
      }
    }
    if (legJson.containsKey('nextLegs') && legJson['nextLegs'] != null) {
      for (final leg in legJson['nextLegs'] as Iterable) {
        if (leg == null) continue;
        otherDepartures.add(
          await Leg.parse(leg as Map<String, dynamic>),
        );
      }
    }

    return Leg(
      id: legJson['id'] as String?,
      mode: legJson['mode'] as String? ?? '',
      headsign: legJson['headsign'] as String?,
      transitLeg: legJson['transitLeg'] as bool,
      realTime: legJson['realTime'] as bool,
      from: await Place.parse(legJson['from'] as Map<String, dynamic>),
      to: await Place.parse(legJson['to'] as Map<String, dynamic>),
      route: route,
      trip: legJson['trip'] != null
          ? Trip.parseWithRoute(
              route,
              legJson['trip'] as Map<String, dynamic>,
            )
          : null,
      duration: legJson['duration'] as num,
      distance: legJson['distance'] as num,
      tripStops: intermediate,
      interlineWithPreviousLeg: legJson['interlineWithPreviousLeg'] as bool,
      otherDepartures: otherDepartures,
      serviceDate: legJson['serviceDate'] as String?,
      geometry: legJson['legGeometry']?['points'] as String?,
    );
  }

  int? get frequency {
    if (from.departure == null ||
        from.departure!.scheduledDateTime == null ||
        otherDepartures.length < 2) {
      return null;
    }

    List<DateTime> departures = [
      from.departure!.scheduledDateTime!,
      ...otherDepartures
          .map((d) => d.from.departure?.scheduledDateTime)
          .where((s) => s != null)
          .map((s) => s!),
    ];

    departures.sort((a, b) => a.compareTo(b));

    int? currentFreqency;

    for (var i = 0; i < departures.length - 1; i++) {
      int diff = departures[i + 1].difference(departures[i]).inMinutes.toInt();
      if (currentFreqency != null && diff != currentFreqency) {
        return null;
      }
      currentFreqency = diff;
    }

    return currentFreqency;
  }
}
