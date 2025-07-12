import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/stop.dart';
import 'package:equatable/equatable.dart';

class Place extends Equatable {
  final String name;
  final double lat;
  final double lon;
  final DepartureArrival? departure;
  final DepartureArrival? arrival;
  final Stop? stop;

  const Place({
    required this.name,
    required this.lat,
    required this.lon,
    this.departure,
    this.arrival,
    this.stop,
  });

  @override
  List<Object> get props => [
        name,
        lat,
        lon,
        departure?.scheduledTime ?? '',
        arrival?.scheduledTime ?? ''
      ];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lon': lon,
      'departure': departure?.toMap(),
      'arrival': arrival?.toMap(),
      'stop': stop != null ? {'gtfsId': stop!.gtfsId} : null,
    };
  }

  static Future<Place> parse(Map<String, dynamic> placeJson) async {
    return Place(
      name: placeJson['name'] as String? ?? 'Unknown',
      lat: (placeJson['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (placeJson['lon'] as num?)?.toDouble() ?? 0.0,
      departure: placeJson['departure'] != null
          ? DepartureArrival.parse(
              placeJson['departure'] as Map<String, dynamic>,
            )
          : null,
      arrival: placeJson['arrival'] != null
          ? DepartureArrival.parse(
              placeJson['arrival'] as Map<String, dynamic>,
            )
          : null,
      stop: placeJson['stop'] != null
          ? await StopDao().get(placeJson['stop']['gtfsId'] as String)
          : null,
    );
  }
}

class DepartureArrival extends Equatable {
  final String? scheduledTime;
  final EstimatedTime? estimated;

  const DepartureArrival({this.scheduledTime, this.estimated});

  @override
  List<Object> get props => [
        scheduledTime ?? '',
        estimated?.time ?? '',
      ];

  Map<String, dynamic> toMap() {
    return {
      'scheduledTime': scheduledTime,
      'estimated': estimated?.toMap(),
    };
  }

  static DepartureArrival parse(Map<String, dynamic> json) {
    return DepartureArrival(
      scheduledTime: json['scheduledTime'] as String?,
      estimated: json['estimated'] != null
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

  String? get realTime {
    if (estimated != null && estimated!.time != null) {
      return estimated!.time;
    } else {
      return scheduledTime;
    }
  }

  DateTime? get realDateTime {
    return realTime != null ? DateTime.tryParse(realTime!) : null;
  }

  DateTime? get scheduledDateTime {
    if (scheduledTime == null) return null;
    return DateTime.tryParse(scheduledTime!);
  }
}

class EstimatedTime {
  final String? time;
  final String? delay;

  EstimatedTime({this.time, this.delay});

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'delay': delay,
    };
  }

  static EstimatedTime parse(Map<String, dynamic> json) {
    return EstimatedTime(
      time: json['time'] as String?,
      delay: json['delay'] as String?,
    );
  }
}
