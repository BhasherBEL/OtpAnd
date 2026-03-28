import 'package:flutter/material.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/objects/place.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/objects/route.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/timed_stop.dart';

Place makePlace({
  String name = 'Test Stop',
  double lat = 50.8,
  double lon = 4.3,
  DepartureArrival? departure,
  DepartureArrival? arrival,
  Stop? stop,
}) {
  return Place(
    name: name,
    lat: lat,
    lon: lon,
    departure: departure,
    arrival: arrival,
    stop: stop,
  );
}

Leg makeLeg({
  String? id,
  String mode = 'WALK',
  bool transitLeg = false,
  bool realTime = false,
  Place? from,
  Place? to,
  RouteInfo? route,
  num duration = 600,
  num distance = 800,
  List<TimedStop>? tripStops,
  bool interlineWithPreviousLeg = false,
  List<Leg> otherDepartures = const [],
  TransferRisk? transferRisk,
}) {
  return Leg(
    id: id,
    mode: mode,
    transitLeg: transitLeg,
    realTime: realTime,
    from: from ?? makePlace(name: 'From', lat: 50.8, lon: 4.3),
    to: to ?? makePlace(name: 'To', lat: 50.9, lon: 4.4),
    route: route,
    duration: duration,
    distance: distance,
    tripStops: tripStops,
    interlineWithPreviousLeg: interlineWithPreviousLeg,
    otherDepartures: otherDepartures,
    transferRisk: transferRisk,
  );
}

Plan makePlan({
  int? id,
  String start = '2024-01-01T10:00:00',
  String end = '2024-01-01T11:00:00',
  String fromName = 'Origin',
  String toName = 'Destination',
  List<Leg>? legs,
  Map<String, dynamic>? raw,
}) {
  return Plan(
    id: id,
    start: start,
    end: end,
    fromName: fromName,
    toName: toName,
    legs: legs ?? [makeLeg()],
    raw: raw ?? {},
  );
}

RouteInfo makeRouteInfo({
  String gtfsId = 'agency:1',
  String longName = 'Test Route Long',
  String shortName = '42',
  Color? color,
  Color? textColor,
  RouteMode mode = RouteMode.bus,
}) {
  return RouteInfo(
    gtfsId: gtfsId,
    longName: longName,
    shortName: shortName,
    color: color,
    textColor: textColor,
    mode: mode,
  );
}

Stop makeStop({
  String gtfsId = 'agency:stop1',
  String name = 'Test Stop',
  String? platformCode,
  double lat = 50.8,
  double lon = 4.3,
  String? mode,
}) {
  return Stop(
    gtfsId: gtfsId,
    name: name,
    platformCode: platformCode,
    lat: lat,
    lon: lon,
    mode: mode,
  );
}

TimedStop makeTimedStop({
  Stop? stop,
  DepartureArrival? arrival,
  DepartureArrival? departure,
  PickupDropoffType? pickupType,
  PickupDropoffType? dropoffType,
}) {
  return TimedStop(
    stop: stop ?? makeStop(),
    arrival: arrival ??
        const DepartureArrival(scheduledTime: '2024-01-01T10:00:00'),
    departure: departure ??
        const DepartureArrival(scheduledTime: '2024-01-01T10:00:30'),
    pickupType: pickupType,
    dropoffType: dropoffType,
  );
}
