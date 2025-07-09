import 'package:flutter/material.dart';
import 'package:otpand/pages/profile/card.dart';

class WalkingSettingsSection extends StatelessWidget {
  final bool avoidDirectWalking;
  final double walkPreference;
  final double walkSafetyPreference;
  final double walkSpeed;
  final Function(bool) onAvoidDirectWalkingChanged;
  final Function(double) onWalkPreferenceChanged;
  final Function(double) onWalkSafetyPreferenceChanged;
  final Function(double) onWalkSpeedChanged;

  const WalkingSettingsSection({
    super.key,
    required this.avoidDirectWalking,
    required this.walkPreference,
    required this.walkSafetyPreference,
    required this.walkSpeed,
    required this.onAvoidDirectWalkingChanged,
    required this.onWalkPreferenceChanged,
    required this.onWalkSafetyPreferenceChanged,
    required this.onWalkSpeedChanged,
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
      title: 'Walking',
      initialState: true,
      onStateChanged: (_) {},
      hasBorder: true,
      children: [
        _buildSwitchTile(
          title: 'Avoid direct walking',
          description: 'Avoid routes that require walking directly to the destination.',
          value: avoidDirectWalking,
          onChanged: onAvoidDirectWalkingChanged,
        ),
        _buildSliderTile(
          title: 'Walk preference',
          description: 'How much you prefer walking over other modes.',
          value: walkPreference,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          onChanged: onWalkPreferenceChanged,
        ),
        _buildSliderTile(
          title: 'Walk safety preference',
          description: 'How much you value safe walking routes.',
          value: walkSafetyPreference,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: onWalkSafetyPreferenceChanged,
        ),
        _buildSliderTile(
          title: 'Walk speed',
          description: 'Your average walking speed (km/h).',
          value: walkSpeed,
          min: 2.0,
          max: 10.0,
          divisions: 16,
          onChanged: onWalkSpeedChanged,
          valueSuffix: 'km/h',
        ),
      ],
    );
  }
}

