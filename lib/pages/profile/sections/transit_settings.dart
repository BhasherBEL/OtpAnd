import 'package:flutter/material.dart';
import 'package:otpand/pages/profile/card.dart';

class TransitSettingsSection extends StatelessWidget {
  final bool transit;
  final double transitPreference;
  final double transitWaitReluctance;
  final double transitTransferWorth;
  final int transitMinimalTransferTime;
  final bool wheelchairAccessible;
  final bool enableModeBus;
  final double preferenceModeBus;
  final bool enableModeMetro;
  final double preferenceModeMetro;
  final bool enableModeTram;
  final double preferenceModeTram;
  final bool enableModeTrain;
  final double preferenceModeTrain;
  final bool enableModeFerry;
  final double preferenceModeFerry;
  final Function(bool) onTransitChanged;
  final Function(double) onTransitPreferenceChanged;
  final Function(double) onTransitWaitReluctanceChanged;
  final Function(double) onTransitTransferWorthChanged;
  final Function(int) onTransitMinimalTransferTimeChanged;
  final Function(bool) onWheelchairAccessibleChanged;
  final Function(bool) onEnableModeBusChanged;
  final Function(double) onPreferenceModeBusChanged;
  final Function(bool) onEnableModeMetroChanged;
  final Function(double) onPreferenceModeMetroChanged;
  final Function(bool) onEnableModeTramChanged;
  final Function(double) onPreferenceModeTramChanged;
  final Function(bool) onEnableModeTrainChanged;
  final Function(double) onPreferenceModeTrainChanged;
  final Function(bool) onEnableModeFerryChanged;
  final Function(double) onPreferenceModeFerryChanged;

  const TransitSettingsSection({
    super.key,
    required this.transit,
    required this.transitPreference,
    required this.transitWaitReluctance,
    required this.transitTransferWorth,
    required this.transitMinimalTransferTime,
    required this.wheelchairAccessible,
    required this.enableModeBus,
    required this.preferenceModeBus,
    required this.enableModeMetro,
    required this.preferenceModeMetro,
    required this.enableModeTram,
    required this.preferenceModeTram,
    required this.enableModeTrain,
    required this.preferenceModeTrain,
    required this.enableModeFerry,
    required this.preferenceModeFerry,
    required this.onTransitChanged,
    required this.onTransitPreferenceChanged,
    required this.onTransitWaitReluctanceChanged,
    required this.onTransitTransferWorthChanged,
    required this.onTransitMinimalTransferTimeChanged,
    required this.onWheelchairAccessibleChanged,
    required this.onEnableModeBusChanged,
    required this.onPreferenceModeBusChanged,
    required this.onEnableModeMetroChanged,
    required this.onPreferenceModeMetroChanged,
    required this.onEnableModeTramChanged,
    required this.onPreferenceModeTramChanged,
    required this.onEnableModeTrainChanged,
    required this.onPreferenceModeTrainChanged,
    required this.onEnableModeFerryChanged,
    required this.onPreferenceModeFerryChanged,
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
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Wheelchair accessible',
          description: 'Prefer only wheelchair accessible routes.',
          value: wheelchairAccessible,
          onChanged: onWheelchairAccessibleChanged,
        ),
        const SizedBox(height: 16),
        ProfileCardWidget(
          title: 'Transit',
          description: 'Allow using public transport.',
          initialState: transit,
          onStateChanged: onTransitChanged,
          hasBorder: true,
          children: [
            _buildSliderTile(
              title: 'Transit preference',
              description: 'How much you prefer transit over other modes.',
              value: transitPreference,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: onTransitPreferenceChanged,
            ),
            _buildSliderTile(
              title: 'Transit wait reluctance',
              description: 'How much you dislike waiting for transit.',
              value: transitWaitReluctance,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: onTransitWaitReluctanceChanged,
            ),
            _buildSliderTile(
              title: 'Transit transfer worth',
              description: 'How much a transfer is worth in minutes.',
              value: transitTransferWorth,
              min: 0.0,
              max: 15.0,
              divisions: 15,
              onChanged: onTransitTransferWorthChanged,
              valueSuffix: 'min',
            ),
            ListTile(
              title: const Text('Minimal transfer time'),
              subtitle: const Text(
                'Minimum time (in seconds) required for a transfer.',
              ),
              trailing: SizedBox(
                width: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: transitMinimalTransferTime > 0
                          ? () => onTransitMinimalTransferTimeChanged(
                                transitMinimalTransferTime - 1,
                              )
                          : null,
                    ),
                    Text('$transitMinimalTransferTime m'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: transitMinimalTransferTime < 60
                          ? () => onTransitMinimalTransferTimeChanged(
                                transitMinimalTransferTime + 1,
                              )
                          : null,
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
            ),
            const Divider(),
            const Text(
              'Modes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ProfileCardWidget(
              title: 'Bus',
              initialState: enableModeBus,
              onStateChanged: onEnableModeBusChanged,
              children: [
                _buildSliderTile(
                  title: 'Preference for bus',
                  value: preferenceModeBus,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: onPreferenceModeBusChanged,
                ),
              ],
            ),
            ProfileCardWidget(
              title: 'Tram',
              initialState: enableModeTram,
              onStateChanged: onEnableModeTramChanged,
              children: [
                _buildSliderTile(
                  title: 'Preference for tram',
                  value: preferenceModeTram,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: onPreferenceModeTramChanged,
                ),
              ],
            ),
            ProfileCardWidget(
              title: 'Metro',
              initialState: enableModeMetro,
              onStateChanged: onEnableModeMetroChanged,
              children: [
                _buildSliderTile(
                  title: 'Preference for metro',
                  value: preferenceModeMetro,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: onPreferenceModeMetroChanged,
                ),
              ],
            ),
            ProfileCardWidget(
              title: 'Train',
              initialState: enableModeTrain,
              onStateChanged: onEnableModeTrainChanged,
              children: [
                _buildSliderTile(
                  title: 'Preference for train',
                  value: preferenceModeTrain,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: onPreferenceModeTrainChanged,
                ),
              ],
            ),
            ProfileCardWidget(
              title: 'Ferry',
              initialState: enableModeFerry,
              onStateChanged: onEnableModeFerryChanged,
              children: [
                _buildSliderTile(
                  title: 'Preference for ferry',
                  value: preferenceModeFerry,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: onPreferenceModeFerryChanged,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

