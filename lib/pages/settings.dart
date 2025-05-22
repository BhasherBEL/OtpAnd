import 'package:flutter/material.dart';
import 'package:otpand/pages/otpconfig.dart';
import 'package:otpand/pages/profiles.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otpand/utils/gnss.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _sortStopsByDistance = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortStopsByDistance =
          prefs.getBool('otp_sort_stops_by_distance') ?? false;
      _loading = false;
    });
  }

  Future<void> _setSortStopsByDistance(bool value) async {
    if (value) {
      bool gpsAvailable = false;
      try {
        final loc = await getCurrentLocation();
        gpsAvailable = loc != null;
      } catch (_) {
        gpsAvailable = false;
      }
      if (!gpsAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS access is required to sort stops by distance.'),
          ),
        );
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('otp_sort_stops_by_distance', value);
    setState(() {
      _sortStopsByDistance = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Sort stops by distance'),
                    subtitle: const Text(
                      'Show stops nearest to your current location first. Requires GPS access.',
                    ),
                    value: _sortStopsByDistance,
                    onChanged: (value) => _setSortStopsByDistance(value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profiles'),
                    subtitle: const Text('Manage your travel profiles'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfilesPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_applications),
                    title: const Text('OTP Configuration'),
                    subtitle: const Text(
                      'Configure your OpenTripPlanner instance',
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const OtpConfigPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
    );
  }
}
