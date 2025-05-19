import 'package:flutter/material.dart';

class Profile {
  String name;
  Color color;
  String mode;

  Profile({required this.name, required this.color, required this.mode});

  // For debugging: a blank profile
  factory Profile.blank() =>
      Profile(name: '', color: Colors.blue, mode: 'Transit');

  Profile copyWith({String? name, Color? color, String? mode}) {
    return Profile(
      name: name ?? this.name,
      color: color ?? this.color,
      mode: mode ?? this.mode,
    );
  }
}
