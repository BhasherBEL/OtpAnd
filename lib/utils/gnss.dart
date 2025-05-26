import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:otpand/objs.dart';

Future<bool> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

Future<bool> isLocationAvailable() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;
  return await requestLocationPermission();
}

Future<Location?> getCurrentLocation() async {
  if (!await isLocationAvailable()) return null;

  final pos = await Geolocator.getCurrentPosition();
  return Location(
    name: "Current Location",
    displayName: "Current Location",
    lat: pos.latitude,
    lon: pos.longitude,
  );
}

Future<double?> distanceToCurrentLocation(double lat, double lon) async {
  if (!await isLocationAvailable()) return null;

  final current = await Geolocator.getCurrentPosition();
  return Geolocator.distanceBetween(
    lat,
    lon,
    current.latitude,
    current.longitude,
  );
}

Future<List<double?>> distancesToCurrentLocation(
  List<Location> locations,
) async {
  if (!await isLocationAvailable()) return List.filled(locations.length, null);

  final current = await Geolocator.getCurrentPosition();
  return locations.map((loc) {
    return Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      loc.lat,
      loc.lon,
    );
  }).toList();
}

Future<(double, double)?> resolveAddress(
  String address, {
  BuildContext? context,
}) async {
  if (address.isEmpty) return null;
  try {
    final locations = await geocoding.locationFromAddress(address);

    if (locations.isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to find a location for this address.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return null;
    }

    return (locations.first.latitude, locations.first.longitude);
  } catch (e) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), duration: Duration(seconds: 3)),
      );
    }
  }
  return null;
}
