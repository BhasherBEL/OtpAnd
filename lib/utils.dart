import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'objs.dart';

num round(num n, int demicals) {
  if (demicals < 0) {
    return (n / pow(10, -demicals)).round() * pow(10, -demicals);
  }
  if (demicals == 0) {
    return n.round();
  }
  return double.parse(n.toStringAsFixed(demicals));
}

String displayDistance(num distance) {
  if (distance < 100) {
    return '${round(distance, -1)}m';
  }
  if (distance < 1000) {
    return '${round(distance, -2)}m';
  }
  if (distance < 10000) {
    return '${round(distance / 1000, 1)}km';
  }
  return '${round(distance / 1000, 0)}km';
}

String displayTime(num time) {
  if (time < 60) {
    return '${round(time, -1)} sec';
  }
  if (time < 3600) {
    return '${round(time / 60, 0)} min';
  }
  return '${round(time / 3600, 0)} h ${round((time % 3600) / 60, 0)} min';
}

String displayDistanceInTime(num distance) {
  final time = distance / 1.11;
  if (time < 3600) {
    return '${max(round(time / 60, 0), 1)}';
  }
  if (time % 3600 == 0) {
    return '${round(time / 3600, 0)}h';
  }
  return '${round(time / 3600, 0)}h${round((time % 3600) / 60, 0)}';
}

Color? getColorFromCode(dynamic code) {
  if (code == null) return null;
  if (code is int) {
    String hex = code.toRadixString(16).padLeft(6, '0');
    return Color(int.parse('FF$hex', radix: 16));
  }
  if (code is String) {
    String hex = code.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
  return null;
}

IconData iconForMode(String mode) {
  switch (mode) {
    case "WALK":
      return Icons.directions_walk;
    case "BICYCLE":
      return Icons.directions_bike;
    case "CAR":
      return Icons.directions_car;
    case "BUS":
      return Icons.directions_bus;
    case "RAIL":
    case "SUBWAY":
      return Icons.train;
    case "TRAM":
      return Icons.tram;
    case "FERRY":
      return Icons.directions_boat;
    default:
      return Icons.trip_origin;
  }
}

Color colorForMode(String mode) {
  switch (mode) {
    case "WALK":
      return Colors.green;
    case "BUS":
      return Colors.blue;
    case "SUBWAY":
      return Colors.deepOrange;
    case "TRAM":
      return Colors.purple;
    case "RAIL":
      return Colors.teal;
    default:
      return Colors.grey.shade400;
  }
}

String? formatTime(String? iso) {
  if (iso == null) return null;
  try {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('HH:mm').format(dt);
  } catch (_) {
    return iso;
  }
}

String legDescription(Leg leg) {
  if (leg.mode == "WALK") {
    return "Walk";
  } else if (leg.mode == "BICYCLE") {
    return "Bike";
  } else if (leg.mode == "CAR") {
    return "Car";
  } else if (leg.mode == "BUS" ||
      leg.mode == "RAIL" ||
      leg.mode == "SUBWAY" ||
      leg.mode == "TRAM" ||
      leg.mode == "FERRY") {
    String route =
        leg.route?.shortName != null ? " ${leg.route!.shortName}" : "";
    return "${capitalize(leg.mode)}$route";
  } else if (leg.route != null) {
    String route =
        leg.route!.shortName != null ? " ${leg.route!.shortName}" : "";
    return "${capitalize(leg.mode)}$route";
  }
  return capitalize(leg.mode);
}

String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;

String calculateDuration(DateTime start, DateTime end) {
  final duration = end.difference(start);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}min';
  } else {
    return '${minutes}min';
  }
}

num calculateDurationFromString(String? start, String? end) {
  if (start == null || end == null) return 0;
  try {
    final startTime = DateTime.parse(start).toLocal();
    final endTime = DateTime.parse(end).toLocal();
    return endTime.difference(startTime).inSeconds;
  } catch (e) {
    return 0;
  }
}
