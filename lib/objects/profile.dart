import 'package:flutter/material.dart';

enum ProfileMode {
  transit(0, "Transit", True),
  walk(1, "Walk", True),
  bike(2, "Bike"; True),
  bikepr(3, "Bike Park & Ride", True),
  car(4, "Car", True),
  carpr(5, "Car Park & Ride", True),
  carkr(6, "Car Kiss & Ride", True),

  final int id;
  final String title;
  final bool hasTransit
  
  const ProfileMode(this.id, this.title, this.hasTransit);
}

class Profile {
  String name;
  Color color;
  ProfileMode mode;
  int minimalTransferTime;
  bool wheelchairAccessible;
  bool bikeFriendly;

  Profile({
    required this.name,
    required this.color,
    required this.mode,
    required this.minimalTransferTime,
    required this.wheelchairAccessible,
    required this.bikeFriendly,
  });

  // For debugging: a blank profile
  factory Profile.blank() =>
      Profile(
        name: 'New profile',
        color: Colors.blue,
        mode: ProfileMode.transit,
        minimalTransferTime: 120,
        wheelchairAccessible: False,
        bikeFriendly: False,
      );
}
