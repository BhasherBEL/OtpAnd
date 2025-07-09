import 'package:flutter/material.dart';
import 'package:otpand/objects/agency.dart';
import 'package:otpand/pages/profile/card.dart';

class AgencySettingsSection extends StatelessWidget {
  final Map<Agency, bool> agenciesEnabled;
  final Function(Agency, bool) onAgencyChanged;

  const AgencySettingsSection({
    super.key,
    required this.agenciesEnabled,
    required this.onAgencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (agenciesEnabled.isEmpty) {
      return const SizedBox.shrink();
    }

    return ProfileCardWidget(
      title: 'Agencies',
      description: 'Select which transit agencies to use.',
      initialState: true,
      onStateChanged: (_) {},
      hasBorder: true,
      children: agenciesEnabled.entries.map((entry) {
        return CheckboxListTile(
          title: Text(entry.key.name ?? entry.key.gtfsId),
          value: entry.value,
          onChanged: (bool? value) {
            onAgencyChanged(entry.key, value ?? false);
          },
        );
      }).toList(),
    );
  }
}

