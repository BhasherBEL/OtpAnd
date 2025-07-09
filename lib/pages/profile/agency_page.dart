import 'package:flutter/material.dart';
import 'package:otpand/objects/agency.dart';
import 'package:otpand/objects/profile.dart';

class AgencySettingsPage extends StatefulWidget {
  final Profile profile;

  const AgencySettingsPage({super.key, required this.profile});

  @override
  State<AgencySettingsPage> createState() => _AgencySettingsPageState();
}

class _AgencySettingsPageState extends State<AgencySettingsPage> {
  late Map<Agency, bool> agenciesEnabled;

  @override
  void initState() {
    super.initState();
    agenciesEnabled = Map.from(widget.profile.agenciesEnabled);
    ensureAgencies();
    Agency.currentAgencies.addListener(ensureAgencies);
  }

  @override
  void dispose() {
    Agency.currentAgencies.removeListener(ensureAgencies);
    super.dispose();
  }

  void ensureAgencies() {
    setState(() {
      for (Agency agency in Agency.currentAgencies.value) {
        if (!agenciesEnabled.containsKey(agency)) {
          agenciesEnabled[agency] = true;
        }
      }
    });
  }

  void _saveSettings() {
    widget.profile.agenciesEnabled = agenciesEnabled;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (agenciesEnabled.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agency Settings'),
        ),
        body: const Center(
          child: Text(
            'No transit agencies available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select which transit agencies to use for route planning:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: agenciesEnabled.entries.map((entry) {
                  return Card(
                    child: CheckboxListTile(
                      title: Text(entry.key.name ?? entry.key.gtfsId),
                      subtitle: Text(entry.key.gtfsId),
                      value: entry.value,
                      onChanged: (bool? value) {
                        setState(() {
                          agenciesEnabled[entry.key] = value ?? false;
                        });
                      },
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

