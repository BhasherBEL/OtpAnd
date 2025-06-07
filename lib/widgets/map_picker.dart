import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/utils/gnss.dart';

class MapPicker extends StatefulWidget {
  const MapPicker({super.key});

  @override
  MapPickerState createState() => MapPickerState();
}

class MapPickerState extends State<MapPicker> {
  LatLng? _selectedPosition;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick a Location'),
        actions: [
          IconButton(
            icon:
                isLoading
                    ? CircularProgressIndicator(strokeWidth: 2)
                    : Icon(Icons.check),
            onPressed: () async {
              if (_selectedPosition == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a location on the map.'),
                  ),
                );
                return;
              }

              setState(() => isLoading = true);
              final address = await resolveGeocode(
                _selectedPosition!.latitude,
                _selectedPosition!.longitude,
              );
              if (!context.mounted) return;
              Navigator.of(context).pop(
                Location(
                  name: address ?? 'Selected Location',
                  displayName: address ?? 'Selected Location',
                  lat: _selectedPosition!.latitude,
                  lon: _selectedPosition!.longitude,
                  stop: null,
                ),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          keepAlive: true,
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          initialZoom: 8.0,
          initialCenter: _selectedPosition ?? LatLng(50.846558, 4.351694),
          onTap: (tapPosition, point) {
            setState(() {
              _selectedPosition = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              if (_selectedPosition != null)
                Marker(
                  point: _selectedPosition!,
                  child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                  alignment: Alignment.topCenter,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
