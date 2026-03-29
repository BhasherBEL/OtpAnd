import 'package:flutter/material.dart';

const primary500 = Color(0xFF198DE5);
const primary50 = Color(0xFFE3F2FD);

/// Foreground color for transfer reliability badges and dots.
/// ≥ 90 %: green  ≥ 75 %: amber  ≥ 55 %: orange  else: red
Color transferReliabilityFg(double r) {
  final pct = (r * 100).round();
  if (pct >= 90) return Colors.green.shade700;
  if (pct >= 75) return Colors.amber.shade800;
  if (pct >= 55) return Colors.orange.shade800;
  return Colors.red.shade800;
}

/// Background color for transfer reliability badges.
Color transferReliabilityBg(double r) {
  final pct = (r * 100).round();
  if (pct >= 90) return Colors.green.shade50;
  if (pct >= 75) return Colors.amber.shade50;
  if (pct >= 55) return Colors.orange.shade50;
  return Colors.red.shade50;
}
