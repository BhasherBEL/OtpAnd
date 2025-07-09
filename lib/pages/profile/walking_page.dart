import 'package:flutter/material.dart';
import 'package:otpand/objects/profile.dart';

class WalkingSettingsPage extends StatefulWidget {
  final Profile profile;

  const WalkingSettingsPage({super.key, required this.profile});

  @override
  State<WalkingSettingsPage> createState() => _WalkingSettingsPageState();
}

class _WalkingSettingsPageState extends State<WalkingSettingsPage> {
  late bool avoidDirectWalking;
  late double walkPreference;
  late double walkSafetyPreference;
  late double walkSpeed;

  @override
  void initState() {
    super.initState();
    avoidDirectWalking = widget.profile.avoidDirectWalking;
    walkPreference = widget.profile.walkPreference;
    walkSafetyPreference = widget.profile.walkSafetyPreference;
    walkSpeed = widget.profile.walkSpeed;
  }

  void _saveSettings() {
    widget.profile.avoidDirectWalking = avoidDirectWalking;
    widget.profile.walkPreference = walkPreference;
    widget.profile.walkSafetyPreference = walkSafetyPreference;
    widget.profile.walkSpeed = walkSpeed;
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
        title: const Text('Walking Settings'),
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
              title: 'Avoid direct walking',
              description: 'Avoid routes that require walking directly to the destination.',
              value: avoidDirectWalking,
              onChanged: (v) => setState(() => avoidDirectWalking = v),
            ),
            const SizedBox(height: 16),
            _buildSliderTile(
              title: 'Walk preference',
              description: 'How much you prefer walking over other modes.',
              value: walkPreference,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (v) => setState(() => walkPreference = v),
            ),
            const SizedBox(height: 16),
            _buildSliderTile(
              title: 'Walk safety preference',
              description: 'How much you value safe walking routes.',
              value: walkSafetyPreference,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (v) => setState(() => walkSafetyPreference = v),
            ),
            const SizedBox(height: 16),
            _buildSliderTile(
              title: 'Walk speed',
              description: 'Your average walking speed.',
              value: walkSpeed,
              min: 2.0,
              max: 10.0,
              divisions: 16,
              onChanged: (v) => setState(() => walkSpeed = v),
              valueSuffix: 'km/h',
            ),
          ],
        ),
      ),
    );
  }
}

