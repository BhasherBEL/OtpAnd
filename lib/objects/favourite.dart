import 'package:flutter/material.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/stop.dart';

class Favourite {
  final int id;
  final String name;
  final double lat;
  final double lon;
  final Stop? stop;
  final bool isContact;

  Favourite({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.stop,
    this.isContact = false,
  });

  static Future<Favourite> parse(Map<String, dynamic> json) async {
    return Favourite(
      id: json['id'] as int,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      stop: json['stopGtfsId'] != null
          ? await StopDao().get(json['stopGtfsId'] as String)
          : null,
      isContact: json['isContact'] == 1 || json['isContact'] == true,
    );
  }

  Location toLocation() {
    return Location(
      name: name,
      lat: lat,
      lon: lon,
      stop: stop,
      displayName: name,
    );
  }

  static final currentFavourites = ValueNotifier<List<Favourite>>([]);
}
