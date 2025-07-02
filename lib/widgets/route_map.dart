import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:otpand/objects/plan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class RouteMapWidget extends StatefulWidget {
  final Plan plan;

  const RouteMapWidget({super.key, required this.plan});

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  bool showLiveLocation = false;
  Position? currentPosition;
  StreamSubscription<Position>? positionStream;

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> _toggleLiveLocation() async {
    if (showLiveLocation) {
      // Disable live location
      setState(() {
        showLiveLocation = false;
        currentPosition = null;
      });
      await positionStream?.cancel();
    } else {
      // Enable live location
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location services are disabled.')),
            );
          }
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Location permissions are denied')),
              );
            }
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permissions are permanently denied, we cannot request permissions.'),
              ),
            );
          }
          return;
        }

        setState(() {
          showLiveLocation = true;
        });

        // Start listening to location updates
        positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              currentPosition = position;
            });
          }
        });
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error enabling live location: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            keepAlive: true,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            initialCameraFit: CameraFit.bounds(
              bounds: widget.plan.getBounds(),
              padding: const EdgeInsets.only(
                left: 64,
                top: 64,
                right: 64,
                bottom: 512,
              ),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.otpand',
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                ),
                TextSourceAttribution(
                  'The best way to help the community is to contribute.',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/fixthemap'),
                  ),
                  prependCopyright: false,
                ),
              ],
            ),
            PolylineLayer(
                polylines:
                    widget.plan.legs.map((leg) => leg.polyline).toList()),
            MarkerLayer(
              markers: widget.plan.legs
                  .where((leg) => leg.route != null)
                  .map(
                    (leg) => Marker(
                      point: leg.midPoint,
                      width:
                          min(max(leg.route!.shortName.length * 12.5, 30), 75),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: leg.route!.color ?? leg.route!.mode.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          leg.route!.shortName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: leg.route!.textColor ?? Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                    ),
                  )
                  .toList(),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(widget.plan.legs.first.from.lat,
                      widget.plan.legs.first.from.lon),
                  child: Icon(Icons.place, color: Colors.green, size: 40),
                ),
                Marker(
                  point: LatLng(widget.plan.legs.last.to.lat,
                      widget.plan.legs.last.to.lon),
                  child: Icon(Icons.place, color: Colors.red, size: 40),
                ),
              ],
            ),
            // Live location marker
            if (showLiveLocation && currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                        currentPosition!.latitude, currentPosition!.longitude),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: Icon(
                showLiveLocation ? Icons.my_location : Icons.location_disabled),
            onPressed: _toggleLiveLocation,
            tooltip: showLiveLocation
                ? 'Disable live location'
                : 'Enable live location',
          ),
        ),
      ],
    );
  }
}
