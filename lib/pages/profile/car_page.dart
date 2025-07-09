import 'package:flutter/material.dart';
import 'package:otpand/objects/profile.dart';

class CarSettingsPage extends StatefulWidget {
  final Profile profile;

  const CarSettingsPage({super.key, required this.profile});

  @override
  State<CarSettingsPage> createState() => _CarSettingsPageState();
}

class _CarSettingsPageState extends State<CarSettingsPage> {
  late bool car;
  late double carPreference;
  late bool carParkRide;
  late bool carKissRide;
  late bool carPickup;

  @override
  void initState() {
    super.initState();
    car = widget.profile.car;
    carPreference = widget.profile.carPreference;
    carParkRide = widget.profile.carParkRide;
    carKissRide = widget.profile.carKissRide;
    carPickup = widget.profile.carPickup;
  }

  void _saveSettings() {
    widget.profile.car = car;
    widget.profile.carPreference = carPreference;
    widget.profile.carParkRide = carParkRide;
    widget.profile.carKissRide = carKissRide;
    widget.profile.carPickup = carPickup;
    Navigator.of(context).pop();
  }

  Widget _buildSliderTile({
    required String title,
    String? description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? valueSuffix,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: valueSuffix != null
                        ? '${value.toStringAsFixed(2)} $valueSuffix'
                        : value.toStringAsFixed(2),
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    valueSuffix != null
                        ? '${value.toStringAsFixed(2)} $valueSuffix'
                        : value.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: description != null ? Text(description) : null,
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSwitchTile(
              title: 'Enable car',
              description: 'Allow using a car for transportation.',
              value: car,
              onChanged: (v) => setState(() => car = v),
            ),
            if (car) ...[
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Car preference',
                description: 'How much you prefer driving over other modes.',
                value: carPreference,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                onChanged: (v) => setState(() => carPreference = v),
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Car park & ride',
                description: 'Allow parking your car and continuing by transit.',
                value: carParkRide,
                onChanged: (v) => setState(() => carParkRide = v),
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Car kiss & ride',
                description: 'Allow being dropped off by car at a stop.',
                value: carKissRide,
                onChanged: (v) => setState(() => carKissRide = v),
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Car pickup',
                description: 'Allow being picked up by car at your destination.',
                value: carPickup,
                onChanged: (v) => setState(() => carPickup = v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

