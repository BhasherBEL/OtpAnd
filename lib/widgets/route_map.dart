import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:otpand/objects/plan.dart';
import 'package:otpand/objects/leg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';

// Helper class for vehicle animation segments
class _VehicleSegment {
  final LatLng from;
  final LatLng to;
  final DateTime departure;
  final DateTime arrival;
  final Duration pauseAtEnd;
  _VehicleSegment({
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.pauseAtEnd,
  });
  Duration get travelTime => arrival.difference(departure);
}

class RouteMapWidget extends StatefulWidget {
  final Plan plan;

  const RouteMapWidget({super.key, required this.plan});

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> with TickerProviderStateMixin {
  bool showLiveLocation = false;
  Position? currentPosition;
  StreamSubscription<Position>? positionStream;
  bool showLiveVehicles = true;
  Timer? vehicleUpdateTimer;
  Map<String, Map<String, dynamic>> vehiclePositions = {};
  Map<String, AnimationController> vehicleAnimations = {};
  Map<String, Animation<double>> vehicleProgressAnimations = {};
  
  // Per-leg segment animation state
  Map<String, List<_VehicleSegment>> vehicleSegments = {};
  Map<String, int> vehicleSegmentIndex = {};
  Map<String, DateTime?> vehiclePausedUntil = {};

  DateTime? _safeParseTime(String? s) => s == null ? null : DateTime.tryParse(s);

  @override
  void initState() {
    super.initState();
    _startVehicleTracking();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    vehicleUpdateTimer?.cancel();
    // Dispose all animation controllers
    for (final controller in vehicleAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startVehicleTracking() {
    _initializeVehicleAnimations();
    vehicleUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateVehicleAnimations();
    });
  }

  void _initializeVehicleAnimations() {
    if (!showLiveVehicles) return;

    for (final leg in widget.plan.legs) {
      if (!leg.transitLeg || leg.route == null) continue;

      final vehicleId = '${leg.route!.gtfsId}_${leg.trip?.gtfsId ?? 'unknown'}';
      final departureTime = leg.from.departure?.realDateTime;
      final arrivalTime = leg.to.arrival?.realDateTime;

      if (departureTime != null && arrivalTime != null) {
        _setupVehicleAnimation(vehicleId, leg, departureTime, arrivalTime);
      }
    }
  }

  void _setupVehicleAnimation(String vehicleId, Leg leg, DateTime departureTime, DateTime arrivalTime) {
    final now = DateTime.now();
    
    // Check if vehicle is in transit
    if (now.isBefore(departureTime) || now.isAfter(arrivalTime)) {
      return;
    }

    // Calculate total trip duration
    final totalDuration = arrivalTime.difference(departureTime);
    
    // Calculate remaining time and progress
    final remainingTime = arrivalTime.difference(now);
    final elapsedTime = now.difference(departureTime);
    final currentProgress = elapsedTime.inMilliseconds / totalDuration.inMilliseconds;

    // Dispose existing controller if any
    if (vehicleAnimations.containsKey(vehicleId)) {
      vehicleAnimations[vehicleId]!.dispose();
    }

    // Create new animation controller with remaining time
    final controller = AnimationController(
      duration: remainingTime,
      vsync: this,
    );

    final animation = Tween<double>(
      begin: currentProgress.clamp(0.0, 1.0),
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));

    vehicleAnimations[vehicleId] = controller;
    vehicleProgressAnimations[vehicleId] = animation;

    // Listen to animation updates
    animation.addListener(() {
      if (mounted) {
        final updatedData = _calculateVehiclePositionFromProgress(leg, animation.value);
        if (updatedData != null) {
          setState(() {
            vehiclePositions[vehicleId] = updatedData;
          });
        }
      }
    });

    // Start the animation
    controller.forward();
  }

  void _updateVehicleAnimations() {
    if (!showLiveVehicles) return;

    for (final leg in widget.plan.legs) {
      if (!leg.transitLeg || leg.route == null) continue;

      final vehicleId = '${leg.route!.gtfsId}_${leg.trip?.gtfsId ?? 'unknown'}';
      final departureTime = leg.from.departure?.realDateTime;
      final arrivalTime = leg.to.arrival?.realDateTime;

      if (departureTime != null && arrivalTime != null) {
        final now = DateTime.now();
        
        // Check if we need to start/restart animation
        if (now.isAfter(departureTime) && now.isBefore(arrivalTime)) {
          if (!vehicleAnimations.containsKey(vehicleId) || 
              vehicleAnimations[vehicleId]!.isCompleted) {
            _setupVehicleAnimation(vehicleId, leg, departureTime, arrivalTime);
          }
        } else if (vehicleAnimations.containsKey(vehicleId)) {
          // Vehicle has completed journey, remove animation
          vehicleAnimations[vehicleId]!.dispose();
          vehicleAnimations.remove(vehicleId);
          vehicleProgressAnimations.remove(vehicleId);
          vehiclePositions.remove(vehicleId);
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Map<String, dynamic>? _calculateVehiclePositionFromProgress(Leg leg, double progress) {
    // Check if vehicle is at a station (within 2 minutes of departure/arrival)
    final departureTime = leg.from.departure?.realDateTime;
    final arrivalTime = leg.to.arrival?.realDateTime;
    
    if (departureTime == null || arrivalTime == null) return null;
    
    final totalDuration = arrivalTime.difference(departureTime).inMilliseconds;
    final elapsed = progress * totalDuration;
    final isAtStation = elapsed < 120000 || (totalDuration - elapsed) < 120000;

    LatLng position;
    double bearing = 0.0;

    // Get route geometry points
    if (leg.geometry == null) {
      // Simple linear interpolation between start and end points
      final startLat = leg.from.lat;
      final startLon = leg.from.lon;
      final endLat = leg.to.lat;
      final endLon = leg.to.lon;

      position = LatLng(
        startLat + (endLat - startLat) * progress,
        startLon + (endLon - startLon) * progress,
      );

      // Calculate bearing for direction
      if (!isAtStation) {
        bearing = _calculateBearing(LatLng(startLat, startLon), LatLng(endLat, endLon));
      }
    } else {
      // Use actual route geometry for more accurate positioning
      final result = _interpolateAlongRouteWithBearing(leg.polyline.points, progress);
      position = result['position'] as LatLng;
      bearing = isAtStation ? 0.0 : result['bearing'] as double;
    }

    return {
      'position': position,
      'bearing': bearing,
      'isAtStation': isAtStation,
      'routeProgress': progress,
    };
  }

  Map<String, dynamic>? _calculateVehiclePosition(Leg leg, DateTime currentTime) {
    // Get departure and arrival times
    final departureTime = leg.from.departure?.realDateTime;
    final arrivalTime = leg.to.arrival?.realDateTime;

    if (departureTime == null || arrivalTime == null) return null;

    // Check if vehicle is currently in transit
    if (currentTime.isBefore(departureTime) || currentTime.isAfter(arrivalTime)) {
      return null; // Vehicle hasn't started or has already arrived
    }

    // Calculate progress along the route (0.0 to 1.0)
    final totalDuration = arrivalTime.difference(departureTime).inMilliseconds;
    final elapsed = currentTime.difference(departureTime).inMilliseconds;
    final progress = elapsed / totalDuration;

    // Check if vehicle is at a station (within 2 minutes of departure/arrival)
    final isAtStation = elapsed < 120000 || (totalDuration - elapsed) < 120000; // 2 minutes in milliseconds

    LatLng position;
    double bearing = 0.0;

    // Get route geometry points
    if (leg.geometry == null) {
      // Simple linear interpolation between start and end points
      final startLat = leg.from.lat;
      final startLon = leg.from.lon;
      final endLat = leg.to.lat;
      final endLon = leg.to.lon;

      position = LatLng(
        startLat + (endLat - startLat) * progress,
        startLon + (endLon - startLon) * progress,
      );

      // Calculate bearing for direction
      if (!isAtStation) {
        bearing = _calculateBearing(LatLng(startLat, startLon), LatLng(endLat, endLon));
      }
    } else {
      // Use actual route geometry for more accurate positioning
      final result = _interpolateAlongRouteWithBearing(leg.polyline.points, progress);
      position = result['position'] as LatLng;
      bearing = isAtStation ? 0.0 : result['bearing'] as double;
    }

    return {
      'position': position,
      'bearing': bearing,
      'isAtStation': isAtStation,
      'routeProgress': progress,
    };
  }

  Map<String, dynamic> _interpolateAlongRouteWithBearing(List<LatLng> points, double progress) {
    if (points.isEmpty) return {'position': LatLng(0, 0), 'bearing': 0.0};
    if (points.length == 1) return {'position': points.first, 'bearing': 0.0};

    final distance = Distance();
    
    // Calculate total route distance
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distance(points[i], points[i + 1]);
    }

    // Find target distance along route
    final targetDistance = totalDistance * progress;
    
    // Find the segment containing the target distance
    double currentDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final segmentDistance = distance(points[i], points[i + 1]);
      
      if (currentDistance + segmentDistance >= targetDistance) {
        // Interpolate within this segment
        final segmentProgress = (targetDistance - currentDistance) / segmentDistance;
        
        final position = LatLng(
          points[i].latitude + (points[i + 1].latitude - points[i].latitude) * segmentProgress,
          points[i].longitude + (points[i + 1].longitude - points[i].longitude) * segmentProgress,
        );
        
        final bearing = _calculateBearing(points[i], points[i + 1]);
        
        return {'position': position, 'bearing': bearing};
      }
      
      currentDistance += segmentDistance;
    }

    // Fallback to last point
    return {'position': points.last, 'bearing': 0.0};
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1Rad = start.latitude * pi / 180;
    final lat2Rad = end.latitude * pi / 180;
    final deltaLonRad = (end.longitude - start.longitude) * pi / 180;

    final y = sin(deltaLonRad) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLonRad);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360; // Normalize to 0-360 degrees
  }

  Widget _buildVehicleMarker(Map<String, dynamic> vehicleData, Color color) {
    final bearing = vehicleData['bearing'] as double;
    final isAtStation = vehicleData['isAtStation'] as bool;

    if (isAtStation) {
      // Simple dot when at station
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      );
    } else {
      // Map pin oriented in direction of movement
      return Transform.rotate(
        angle: bearing * pi / 180,
        child: CustomPaint(
          size: Size(20, 24),
          painter: MapPinPainter(color: color),
        ),
      );
    }
  }

  void _toggleVehicleTracking() {
    setState(() {
      showLiveVehicles = !showLiveVehicles;
      if (!showLiveVehicles) {
        vehiclePositions.clear();
        // Dispose all animations when disabling
        for (final controller in vehicleAnimations.values) {
          controller.dispose();
        }
        vehicleAnimations.clear();
        vehicleProgressAnimations.clear();
      } else {
        _initializeVehicleAnimations();
      }
    });
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
                      child: Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                  ),
                ],
              ),
            // Intermediate stops markers
            MarkerLayer(
              markers: widget.plan.legs
                  .where((leg) => leg.transitLeg && leg.intermediateStops.isNotEmpty)
                  .expand((leg) => leg.intermediateStops.map((stop) => Marker(
                        point: LatLng(stop.stop.lat, stop.stop.lon),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: leg.route?.color ?? Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        width: 8,
                        height: 8,
                        alignment: Alignment.center,
                      )))
                  .toList(),
            ),
            // Live vehicle markers
            if (showLiveVehicles && vehiclePositions.isNotEmpty)
              MarkerLayer(
                markers: vehiclePositions.entries.map((entry) {
                  final vehicleId = entry.key;
                  final vehicleData = entry.value;
                  final position = vehicleData['position'] as LatLng;
                  
                  // Find the corresponding leg to get route info
                  final leg = widget.plan.legs.firstWhere(
                    (leg) => leg.transitLeg && 
                             leg.route != null && 
                             '${leg.route!.gtfsId}_${leg.trip?.gtfsId ?? 'unknown'}' == vehicleId,
                    orElse: () => widget.plan.legs.first,
                  );
                  
                  return Marker(
                    point: position,
                    child: _buildVehicleMarker(
                      vehicleData, 
                      leg.route?.color ?? Colors.orange
                    ),
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                  );
                }).toList(),
              ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                    showLiveLocation ? Icons.my_location : Icons.location_disabled),
                onPressed: _toggleLiveLocation,
                tooltip: showLiveLocation
                    ? 'Disable live location'
                    : 'Enable live location',
              ),
              IconButton(
                icon: Icon(
                    showLiveVehicles ? Icons.directions_bus : Icons.directions_bus_outlined),
                onPressed: _toggleVehicleTracking,
                tooltip: showLiveVehicles
                    ? 'Hide live vehicles'
                    : 'Show live vehicles',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MapPinPainter extends CustomPainter {
  final Color color;

  MapPinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    
    // Create teardrop shape pointing upward (in direction of movement)
    final width = size.width;
    final height = size.height;
    
    // Main circle (back part of pin - the "trail")
    final center = Offset(width / 2, height * 0.7);
    final radius = width * 0.3;
    
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Pin point (front part pointing in direction of movement)
    path.moveTo(width / 2 - radius * 0.5, height * 0.7 - radius * 0.8);
    path.lineTo(width / 2, height * 0.1);
    path.lineTo(width / 2 + radius * 0.5, height * 0.7 - radius * 0.8);
    path.close();

    // Draw filled pin
    canvas.drawPath(path, paint);
    
    // Draw stroke
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
