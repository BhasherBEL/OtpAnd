import 'package:flutter/material.dart';
import 'package:otpand/pages/profile/card.dart';

class CarSettingsSection extends StatelessWidget {
  final bool car;
  final double carPreference;
  final bool carParkRide;
  final bool carKissRide;
  final bool carPickup;
  final Function(bool) onCarChanged;
  final Function(double) onCarPreferenceChanged;
  final Function(bool) onCarParkRideChanged;
  final Function(bool) onCarKissRideChanged;
  final Function(bool) onCarPickupChanged;

  const CarSettingsSection({
    super.key,
    required this.car,
    required this.carPreference,
    required this.carParkRide,
    required this.carKissRide,
    required this.carPickup,
    required this.onCarChanged,
    required this.onCarPreferenceChanged,
    required this.onCarParkRideChanged,
    required this.onCarKissRideChanged,
    required this.onCarPickupChanged,
  });

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
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null) Text(description),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueSuffix != null
                ? '${value.toStringAsFixed(2)} $valueSuffix'
                : value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ],
      ),
      trailing: Text(
        valueSuffix != null
            ? '${value.toStringAsFixed(2)} $valueSuffix'
            : value.toStringAsFixed(2),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: description != null ? Text(description) : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileCardWidget(
      title: 'Car',
      description: 'Allow using a car.',
      initialState: car,
      onStateChanged: onCarChanged,
      hasBorder: true,
      children: [
        _buildSliderTile(
          title: 'Car preference',
          description: 'How much you prefer driving over other modes.',
          value: carPreference,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          onChanged: onCarPreferenceChanged,
        ),
        _buildSwitchTile(
          title: 'Car park & ride',
          description: 'Allow parking your car and continuing by transit.',
          value: carParkRide,
          onChanged: onCarParkRideChanged,
        ),
        _buildSwitchTile(
          title: 'Car kiss & ride',
          description: 'Allow being dropped off by car at a stop.',
          value: carKissRide,
          onChanged: onCarKissRideChanged,
        ),
        _buildSwitchTile(
          title: 'Car pickup',
          description: 'Allow being picked up by car at your destination.',
          value: carPickup,
          onChanged: onCarPickupChanged,
        ),
      ],
    );
  }
}

