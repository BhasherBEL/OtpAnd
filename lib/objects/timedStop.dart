import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/stop.dart';
import 'package:otpand/objects/trip.dart';
import 'package:otpand/objs.dart';

enum PickupDropoffType {
  SCHEDULED(),
  NONE(),
  COORDINATE_WITH_DRIVER(),
  CALL_AGENCY();

  static PickupDropoffType? fromString(String? type) {
    if (type == null) return null;
    switch (type) {
      case 'SCHEDULED':
        return PickupDropoffType.SCHEDULED;
      case 'NONE':
        return PickupDropoffType.NONE;
      case 'COORDINATE_WITH_DRIVER':
        return PickupDropoffType.COORDINATE_WITH_DRIVER;
      case 'CALL_AGENCY':
        return PickupDropoffType.CALL_AGENCY;
      default:
        return null;
    }
  }
}

class TimedStop {
  final Stop stop;
  final DepartureArrival arrival;
  final DepartureArrival departure;
  final String? headSign;
  final Trip? trip;
  final String? serviceDate;
  final PickupDropoffType? dropoffType;
  final PickupDropoffType? pickupType;

  TimedStop({
    required this.stop,
    required this.arrival,
    required this.departure,
    this.headSign,
    this.trip,
    this.serviceDate,
    this.dropoffType,
    this.pickupType,
  });

  static Future<TimedStop> parseFromStoptime(
    Stop? stop,
    Map<String, dynamic> json,
  ) async {
    final bool realtime = json['realtime'] == true;
    final int serviceDay = json['serviceDay'] ?? 0;

    String? toIso(int? secondsSinceMidnight) {
      if (secondsSinceMidnight == null) return null;
      final int unix = serviceDay + secondsSinceMidnight;
      final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
      return dt.toIso8601String();
    }

    final String? scheduledArrival = toIso(json['scheduledArrival']);
    final String? realtimeArrival = toIso(json['realtimeArrival']);
    final String? scheduledDeparture = toIso(json['scheduledDeparture']);
    final String? realtimeDeparture = toIso(json['realtimeDeparture']);

    stop ??= await StopDao().get(json['stop']['gtfsId'] as String);

    String? serviceDate;
    if (serviceDay != 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(serviceDay * 1000);
      serviceDate =
          '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    }

    return TimedStop(
      stop: stop!,
      arrival: DepartureArrival(
        scheduledTime: scheduledArrival,
        estimated:
            realtime ? EstimatedTime(time: realtimeArrival, delay: null) : null,
      ),
      departure: DepartureArrival(
        scheduledTime: scheduledDeparture,
        estimated:
            realtime
                ? EstimatedTime(time: realtimeDeparture, delay: null)
                : null,
      ),
      headSign: json['headsign'] as String?,
      trip: json['trip'] != null ? await Trip.parse(json['trip']) : null,
      serviceDate: serviceDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stop': stop.toMap(),
      'arrival': arrival,
      'departure': departure,
      'headSign': headSign,
      'trip': trip?.toMap(),
      'serviceDate': serviceDate,
    };
  }

  bool isPast() {
    if (departure.realTime != null) {
      DateTime dep = DateTime.parse(departure.realTime!);
      return dep.isBefore(DateTime.now());
    } else {
      DateTime arr = DateTime.parse(arrival.realTime!);
      return arr.isBefore(DateTime.now());
    }
  }
}
