import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:otpand/objects/plan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

class RouteMapWidget extends StatelessWidget {
  final Plan plan;

  const RouteMapWidget({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        keepAlive: true,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        initialCameraFit: CameraFit.bounds(
          bounds: plan.getBounds(),
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
              onTap:
                  () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
            ),
            TextSourceAttribution(
              'The best way to help the community is to contribute.',
              onTap:
                  () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/fixthemap'),
                  ),
              prependCopyright: false,
            ),
          ],
        ),
        PolylineLayer(polylines: plan.legs.map((leg) => leg.polyline).toList()),
        MarkerLayer(
          markers:
              plan.legs
                  .where((leg) => leg.route != null)
                  .map(
                    (leg) => Marker(
                      point: leg.midPoint,
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
              point: LatLng(plan.legs.first.from.lat, plan.legs.first.from.lon),
              child: Icon(Icons.place, color: Colors.green, size: 40),
            ),
            Marker(
              point: LatLng(plan.legs.last.to.lat, plan.legs.last.to.lon),
              child: Icon(Icons.place, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}
