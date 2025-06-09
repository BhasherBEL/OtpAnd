import 'dart:math';
import 'package:flutter/material.dart';

/// Generates a light background color for a route based on its name
Color getRouteBackgroundColor(String routeName) {
  // Generate a consistent hash from the route name
  final hash = routeName.hashCode;
  
  // Use the hash to generate consistent RGB values
  final random = Random(hash);
  
  // Generate light pastel colors by keeping saturation and lightness high
  final hue = random.nextDouble() * 360;
  final saturation = 0.3 + random.nextDouble() * 0.2; // 0.3 - 0.5
  final lightness = 0.85 + random.nextDouble() * 0.1; // 0.85 - 0.95
  
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

/// Generates a slightly darker color for text/borders based on the background color
Color getRouteAccentColor(String routeName) {
  final backgroundColor = getRouteBackgroundColor(routeName);
  final hsl = HSLColor.fromColor(backgroundColor);
  
  // Make it darker for better contrast
  return hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor();
}

