import 'dart:math';

import 'package:flutter/material.dart';

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
    return '${round(time, -1)}s';
  }
  if (time < 3600) {
    return '${round(time / 60, 0)}min';
  }
  return '${round(time / 3600, 0)}h${round((time % 3600) / 60, 0)}';
}

Color? getColorFromCode(String? code) {
  if (code == null) return null;
  if (code.length == 6) {
    return Color(int.parse('FF$code', radix: 16));
  }
  return null;
}
