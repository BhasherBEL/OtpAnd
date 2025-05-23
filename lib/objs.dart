import 'package:flutter/material.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/timedStop.dart';
import 'package:otpand/objects/trip.dart';
import 'package:otpand/utils.dart';

class Plan {
  final String start;
  final String end;
  final List<Leg> legs;

  Plan({required this.start, required this.end, required this.legs});
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
  final List<TimedStop>? intermediateStops;
  final bool interlineWithPreviousLeg;
  final List<DepartureArrival> otherDepartures;
  final Trip? trip;
  final String? serviceDate;

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
    this.intermediateStops,
    required this.interlineWithPreviousLeg,
    required this.otherDepartures,
    this.trip,
    this.serviceDate,
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
