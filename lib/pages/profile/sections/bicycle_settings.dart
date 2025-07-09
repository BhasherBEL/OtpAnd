import 'package:flutter/material.dart';
import 'package:otpand/pages/profile/card.dart';

class BicycleSettingsSection extends StatelessWidget {
  final bool bike;
  final double bikePreference;
  final double bikeFlatnessPreference;
  final double bikeSafetyPreference;
  final double bikeSpeed;
  final bool bikeFriendly;
  final bool bikeParkRide;
  final Function(bool) onBikeChanged;
  final Function(double) onBikePreferenceChanged;
  final Function(double) onBikeFlatnessPreferenceChanged;
  final Function(double) onBikeSafetyPreferenceChanged;
  final Function(double) onBikeSpeedChanged;
  final Function(bool) onBikeFriendlyChanged;
  final Function(bool) onBikeParkRideChanged;

  const BicycleSettingsSection({
    super.key,
    required this.bike,
    required this.bikePreference,
    required this.bikeFlatnessPreference,
    required this.bikeSafetyPreference,
    required this.bikeSpeed,
    required this.bikeFriendly,
    required this.bikeParkRide,
    required this.onBikeChanged,
    required this.onBikePreferenceChanged,
    required this.onBikeFlatnessPreferenceChanged,
    required this.onBikeSafetyPreferenceChanged,
    required this.onBikeSpeedChanged,
    required this.onBikeFriendlyChanged,
    required this.onBikeParkRideChanged,
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
      title: 'Bicycle',
      description: 'Allow using a bicycle.',
      initialState: bike,
      onStateChanged: onBikeChanged,
      hasBorder: true,
      children: [
        _buildSliderTile(
          title: 'Bike preference',
          description: 'How much you prefer biking over other modes.',
          value: bikePreference,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          onChanged: onBikePreferenceChanged,
        ),
        _buildSliderTile(
          title: 'Bike flatness preference',
          description: 'How much you prefer flat routes.',
          value: bikeFlatnessPreference,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: onBikeFlatnessPreferenceChanged,
        ),
        _buildSliderTile(
          title: 'Bike safety preference',
          description: 'How much you value safe bike routes.',
          value: bikeSafetyPreference,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: onBikeSafetyPreferenceChanged,
        ),
        _buildSliderTile(
          title: 'Bike speed',
          description: 'Your average cycling speed (km/h).',
          value: bikeSpeed,
          min: 5.0,
          max: 40.0,
          divisions: 35,
          onChanged: onBikeSpeedChanged,
          valueSuffix: 'km/h',
        ),
        _buildSwitchTile(
          title: 'Bike friendly',
          description: 'Prefer bike-friendly routes.',
          value: bikeFriendly,
          onChanged: onBikeFriendlyChanged,
        ),
        _buildSwitchTile(
          title: 'Bike park & ride',
          description: 'Allow parking your bike and continuing by transit.',
          value: bikeParkRide,
          onChanged: onBikeParkRideChanged,
        ),
      ],
    );
  }
}

