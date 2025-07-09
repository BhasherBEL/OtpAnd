import 'package:flutter/material.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/pages/profile/card.dart';

class TransitSettingsPage extends StatefulWidget {
  final Profile profile;

  const TransitSettingsPage({super.key, required this.profile});

  @override
  State<TransitSettingsPage> createState() => _TransitSettingsPageState();
}

class _TransitSettingsPageState extends State<TransitSettingsPage> {
  late bool transit;
  late double transitPreference;
  late double transitWaitReluctance;
  late double transitTransferWorth;
  late int transitMinimalTransferTime;
  late bool wheelchairAccessible;
  late bool enableModeBus;
  late double preferenceModeBus;
  late bool enableModeMetro;
  late double preferenceModeMetro;
  late bool enableModeTram;
  late double preferenceModeTram;
  late bool enableModeTrain;
  late double preferenceModeTrain;
  late bool enableModeFerry;
  late double preferenceModeFerry;

  @override
  void initState() {
    super.initState();
    transit = widget.profile.transit;
    transitPreference = widget.profile.transitPreference;
    transitWaitReluctance = widget.profile.transitWaitReluctance;
    transitTransferWorth = widget.profile.transitTransferWorth;
    transitMinimalTransferTime = widget.profile.transitMinimalTransferTime;
    wheelchairAccessible = widget.profile.wheelchairAccessible;
    enableModeBus = widget.profile.enableModeBus;
    preferenceModeBus = widget.profile.preferenceModeBus;
    enableModeMetro = widget.profile.enableModeMetro;
    preferenceModeMetro = widget.profile.preferenceModeMetro;
    enableModeTram = widget.profile.enableModeTram;
    preferenceModeTram = widget.profile.preferenceModeTram;
    enableModeTrain = widget.profile.enableModeTrain;
    preferenceModeTrain = widget.profile.preferenceModeTrain;
    enableModeFerry = widget.profile.enableModeFerry;
    preferenceModeFerry = widget.profile.preferenceModeFerry;
  }

  void _saveSettings() {
    widget.profile.transit = transit;
    widget.profile.transitPreference = transitPreference;
    widget.profile.transitWaitReluctance = transitWaitReluctance;
    widget.profile.transitTransferWorth = transitTransferWorth;
    widget.profile.transitMinimalTransferTime = transitMinimalTransferTime;
    widget.profile.wheelchairAccessible = wheelchairAccessible;
    widget.profile.enableModeBus = enableModeBus;
    widget.profile.preferenceModeBus = preferenceModeBus;
    widget.profile.enableModeMetro = enableModeMetro;
    widget.profile.preferenceModeMetro = preferenceModeMetro;
    widget.profile.enableModeTram = enableModeTram;
    widget.profile.preferenceModeTram = preferenceModeTram;
    widget.profile.enableModeTrain = enableModeTrain;
    widget.profile.preferenceModeTrain = preferenceModeTrain;
    widget.profile.enableModeFerry = enableModeFerry;
    widget.profile.preferenceModeFerry = preferenceModeFerry;
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
        title: const Text('Transit Settings'),
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
              title: 'Enable transit',
              description: 'Allow using public transport.',
              value: transit,
              onChanged: (v) => setState(() => transit = v),
            ),
            if (transit) ...[
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Wheelchair accessible',
                description: 'Prefer only wheelchair accessible routes.',
                value: wheelchairAccessible,
                onChanged: (v) => setState(() => wheelchairAccessible = v),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Transit preference',
                description: 'How much you prefer transit over other modes.',
                value: transitPreference,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                onChanged: (v) => setState(() => transitPreference = v),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Transit wait reluctance',
                description: 'How much you dislike waiting for transit.',
                value: transitWaitReluctance,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                onChanged: (v) => setState(() => transitWaitReluctance = v),
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                title: 'Transit transfer worth',
                description: 'How much a transfer is worth in minutes.',
                value: transitTransferWorth,
                min: 0.0,
                max: 15.0,
                divisions: 15,
                onChanged: (v) => setState(() => transitTransferWorth = v),
                valueSuffix: 'min',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Minimal transfer time',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minimum time required for a transfer.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: transitMinimalTransferTime > 0
                                ? () => setState(() => transitMinimalTransferTime--)
                                : null,
                          ),
                          Text(
                            '$transitMinimalTransferTime minutes',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: transitMinimalTransferTime < 60
                                ? () => setState(() => transitMinimalTransferTime++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transport Modes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ProfileCardWidget(
                title: 'Bus',
                initialState: enableModeBus,
                onStateChanged: (v) => setState(() => enableModeBus = v),
                hasBorder: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSliderTile(
                      title: 'Preference for bus',
                      value: preferenceModeBus,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      onChanged: (v) => setState(() => preferenceModeBus = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProfileCardWidget(
                title: 'Tram',
                initialState: enableModeTram,
                onStateChanged: (v) => setState(() => enableModeTram = v),
                hasBorder: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSliderTile(
                      title: 'Preference for tram',
                      value: preferenceModeTram,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      onChanged: (v) => setState(() => preferenceModeTram = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProfileCardWidget(
                title: 'Metro',
                initialState: enableModeMetro,
                onStateChanged: (v) => setState(() => enableModeMetro = v),
                hasBorder: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSliderTile(
                      title: 'Preference for metro',
                      value: preferenceModeMetro,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      onChanged: (v) => setState(() => preferenceModeMetro = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProfileCardWidget(
                title: 'Train',
                initialState: enableModeTrain,
                onStateChanged: (v) => setState(() => enableModeTrain = v),
                hasBorder: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSliderTile(
                      title: 'Preference for train',
                      value: preferenceModeTrain,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      onChanged: (v) => setState(() => preferenceModeTrain = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProfileCardWidget(
                title: 'Ferry',
                initialState: enableModeFerry,
                onStateChanged: (v) => setState(() => enableModeFerry = v),
                hasBorder: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSliderTile(
                      title: 'Preference for ferry',
                      value: preferenceModeFerry,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      onChanged: (v) => setState(() => preferenceModeFerry = v),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

