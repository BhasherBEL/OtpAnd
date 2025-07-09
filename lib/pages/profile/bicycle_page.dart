import 'package:flutter/material.dart';
import 'package:otpand/objects/profile.dart';

class BicycleSettingsPage extends StatefulWidget {
  final Profile profile;

  const BicycleSettingsPage({super.key, required this.profile});

  @override
  State<BicycleSettingsPage> createState() => _BicycleSettingsPageState();
}

class _BicycleSettingsPageState extends State<BicycleSettingsPage> {
  late bool bike;
  late double bikePreference;
  late double bikeFlatnessPreference;
  late double bikeSafetyPreference;
  late double bikeSpeed;
  late bool bikeFriendly;
  late bool bikeParkRide;

  @override
  void initState() {
    super.initState();
    bike = widget.profile.bike;
    bikePreference = widget.profile.bikePreference;
    bikeFlatnessPreference = widget.profile.bikeFlatnessPreference;
    bikeSafetyPreference = widget.profile.bikeSafetyPreference;
    bikeSpeed = widget.profile.bikeSpeed;
    bikeFriendly = widget.profile.bikeFriendly;
    bikeParkRide = widget.profile.bikeParkRide;
  }

  void _saveSettings() {
    widget.profile.bike = bike;
    widget.profile.bikePreference = bikePreference;
    widget.profile.bikeFlatnessPreference = bikeFlatnessPreference;
    widget.profile.bikeSafetyPreference = bikeSafetyPreference;
    widget.profile.bikeSpeed = bikeSpeed;
    widget.profile.bikeFriendly = bikeFriendly;
    widget.profile.bikeParkRide = bikeParkRide;
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
        title: const Text('Bicycle Settings'),
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
              title: 'Enable bicycle',
              description: 'Allow using a bicycle for transportation.',
              value: bike,
              onChanged: (v) => setState(() => bike = v),
            ),
            if (bike) ...[
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Bike preference',
                description: 'How much you prefer biking over other modes.',
                value: bikePreference,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                onChanged: (v) => setState(() => bikePreference = v),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Bike flatness preference',
                description: 'How much you prefer flat routes.',
                value: bikeFlatnessPreference,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (v) => setState(() => bikeFlatnessPreference = v),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Bike safety preference',
                description: 'How much you value safe bike routes.',
                value: bikeSafetyPreference,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (v) => setState(() => bikeSafetyPreference = v),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Bike speed',
                description: 'Your average cycling speed.',
                value: bikeSpeed,
                min: 5.0,
                max: 40.0,
                divisions: 35,
                onChanged: (v) => setState(() => bikeSpeed = v),
                valueSuffix: 'km/h',
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Bike friendly',
                description: 'Prefer bike-friendly routes.',
                value: bikeFriendly,
                onChanged: (v) => setState(() => bikeFriendly = v),
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Bike park & ride',
                description: 'Allow parking your bike and continuing by transit.',
                value: bikeParkRide,
                onChanged: (v) => setState(() => bikeParkRide = v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

