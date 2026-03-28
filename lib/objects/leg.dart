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

class TransferRisk {
  final double reliability;        // 0.0–1.0
  final int scheduledDeparture;    // seconds since midnight
  final int? nextDeparture;        // seconds since midnight; null = no more trips
  /// P(boarding next trip on time) — null when no next departure or no delay
  /// model. Always ≥ reliability because the next departure is further away.
  final double? nextReliability;

  const TransferRisk({
    required this.reliability,
    required this.scheduledDeparture,
    this.nextDeparture,
    this.nextReliability,
  });

  /// Seconds until next departure if this connection is missed.
  /// Returns null when there is no next departure or the computed gap is
  /// non-positive (data anomaly — e.g. negative delay pushed nextDeparture
  /// before scheduledDeparture).
  int? get waitIfMissedSecs {
    if (nextDeparture == null) return null;
    final wait = nextDeparture! - scheduledDeparture;
    return wait > 0 ? wait : null;
  }

  factory TransferRisk.fromJson(Map<String, dynamic> json) => TransferRisk(
        reliability: (json['reliability'] as num).toDouble(),
        scheduledDeparture: json['scheduledDeparture'] as int,
        nextDeparture: json['nextDeparture'] as int?,
        nextReliability: (json['nextReliability'] as num?)?.toDouble(),
      );
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
  final List<Leg> otherDepartures;
  final Trip? trip;
  final String? serviceDate;
  final String? geometry;

  /// Ordered coordinate points for rendering the leg on the map.
  /// Populated from maas-rs `geometry { lat lon }` response.
  /// Takes precedence over the OTP-style encoded [geometry] string.
  final List<LatLng>? geometryPoints;

  final TransferRisk? transferRisk;

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
    this.geometryPoints,
    this.transferRisk,
  });

  Color get color {
    if (route?.color != null) return route!.color!;
    if (mode == 'BUS') return Colors.amber;
    if (mode == 'RAIL' || mode == 'TRAIN') return Colors.teal;
    if (mode == 'TRAM') return Colors.purple;
    if (mode == 'SUBWAY' || mode == 'METRO') return Colors.deepOrange;
    if (mode == 'FERRY') return Colors.lightBlue;
    return Colors.grey.shade400;
  }

  Color get lineColor {
    if (route?.color != null) return route!.color!;
    if (mode == 'WALK' || mode == 'CAR' || mode == 'BICYCLE') return Colors.black;
    if (mode == 'BUS') return Colors.amber;
    if (mode == 'RAIL' || mode == 'TRAIN') return Colors.teal;
    if (mode == 'TRAM') return Colors.purple;
    if (mode == 'SUBWAY' || mode == 'METRO') return Colors.deepOrange;
    if (mode == 'FERRY') return Colors.lightBlue;
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

  List<TimedStop> get intermediateStopsWithStop {
    return intermediateStops
        .where((ts) =>
            ts.pickupType == null ||
            ts.dropoffType == null ||
            ts.pickupType != PickupDropoffType.none ||
            ts.dropoffType != PickupDropoffType.none)
        .toList();
  }

  Polyline get polyline {
    final List<LatLng>? points;
    if (geometryPoints != null && geometryPoints!.length >= 2) {
      points = geometryPoints;
    } else if (geometry != null) {
      points = decodePolyline(geometry!).unpackPolyline();
    } else {
      points = null;
    }

    if (points == null) {
      return Polyline(
        points: [LatLng(from.lat, from.lon), LatLng(to.lat, to.lon)],
        color: lineColor,
        strokeWidth: 8.0,
      );
    }

    return Polyline(
      points: points,
      color: route?.color ?? route?.mode.color ?? lineColor,
      strokeWidth: 4.0,
    );
  }

  LatLng get midPoint {
    final dist = Distance();

    final List<LatLng>? points;
    if (geometryPoints != null && geometryPoints!.length >= 2) {
      points = geometryPoints;
    } else if (geometry != null) {
      points = decodePolyline(geometry!).unpackPolyline();
    } else {
      points = null;
    }

    if (points == null) {
      return LatLng((from.lat + to.lat) / 2, (from.lon + to.lon) / 2);
    }

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += dist(points[i], points[i + 1]);
    }

    double middleDistance = totalDistance / 2;
    double currentDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      final newDist = dist(points[i], points[i + 1]);
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

  // https://mobilite.wallonie.be/files/eDocsMobilite/Outils/explicatifs_calculateur_092019.pdf
  double getEmissions() {
    final km = distance / 1000;
    switch (mode) {
      case 'WALK':
        return 0.016 * km;
      case 'BICYCLE':
        return 0.021 * km;
      case 'CAR':
        return 0.271 * km;
      case 'BUS':
        return 0.101 * km;
      case 'RAIL':
      case 'TRAIN':
      case 'TRAM':
      case 'SUBWAY':
      case 'METRO':
        return 0.031 * km;
      default:
        return 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode,
      'headsign': headsign,
      'transitLeg': transitLeg,
      'realTime': realTime,
      'from': from.toMap(),
      'to': to.toMap(),
      'route': route != null
          ? {
              ['gtfsId']: route!.gtfsId,
            }
          : null,
      'duration': duration,
      'distance': distance,
      'tripStops':
          tripStops != null ? tripStops!.map((s) => s.toMap()).toList() : null,
      'interlineWithPreviousLeg': interlineWithPreviousLeg,
      'otherDepartures': otherDepartures.map((d) => d.toMap()).toList(),
      'trip': trip?.toMap(),
      'serviceDate': serviceDate,
      'legGeometry': geometry != null ? {'points': geometry} : null,
    };
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

  /// The leg from [otherDepartures] whose scheduled departure is the soonest
  /// strictly after this leg's own scheduled departure. Returns null if none.
  Leg? get soonestNextDepartureLeg {
    final currentDt = from.departure?.scheduledDateTime;
    if (currentDt == null) return null;
    Leg? best;
    int? minWait;
    for (final other in otherDepartures) {
      final otherDt = other.from.departure?.scheduledDateTime;
      if (otherDt == null) continue;
      final diff = otherDt.difference(currentDt).inSeconds;
      if (diff > 0 && (minWait == null || diff < minWait)) {
        minWait = diff;
        best = other;
      }
    }
    return best;
  }

  /// Wait in seconds to the soonest departure in [otherDepartures] that departs
  /// strictly after this leg's scheduled departure. Returns null if none.
  int? get soonestNextDepartureWaitSecs => soonestNextDepartureLeg
      ?.from.departure?.scheduledDateTime
      ?.difference(from.departure!.scheduledDateTime!)
      .inSeconds;

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

    if (currentFreqency == 0) return null;
    return currentFreqency;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Leg &&
        (id != null && other.id != null && id == other.id ||
            mode == other.mode &&
                transitLeg == other.transitLeg &&
                realTime == other.realTime &&
                from == other.from &&
                to == other.to &&
                route == other.route &&
                duration == other.duration &&
                distance == other.distance &&
                serviceDate == other.serviceDate &&
                geometry == other.geometry);
  }

  @override
  int get hashCode {
    if (id != null) {
      return id.hashCode;
    }
    return Object.hash(
      mode,
      transitLeg,
      realTime,
      from,
      to,
      route,
      duration,
      distance,
      serviceDate,
      geometry,
    );
  }
}
