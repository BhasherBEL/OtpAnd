import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:otpand/pages/otpconfig.dart';
import 'package:otpand/pages/profiles.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:otpand/utils/gnss.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _sortStopsByDistance = false;
  bool _useContactsLocation = false;
  bool _useCalendarsLocation = false;
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
      _useContactsLocation =
          prefs.getBool('otp_use_contacts_location') ?? false;
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

  Future<void> _setUseContactsLocation(bool value) async {
    if (value) {
      bool granted = false;
      try {
        granted = await FlutterContacts.requestPermission(readonly: true);
      } catch (_) {
        granted = false;
      }
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Contacts permission is required to use contact\'s location.',
            ),
          ),
        );
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('otp_use_contacts_location', value);
    setState(() {
      _useContactsLocation = value;
    });
  }

  Future<void> _setUseCalendarsLocation(bool value) async {
    if (value) {
      bool granted = false;
      final calendarPlugin = DeviceCalendarPlugin();
      try {
        var permissionGranted = await calendarPlugin.hasPermissions();
        if (permissionGranted.isSuccess && permissionGranted.data == null ||
            permissionGranted.data == false) {
          permissionGranted = await calendarPlugin.requestPermissions();
          if (permissionGranted.isSuccess &&
              permissionGranted.data != null &&
              permissionGranted.data == true) {
            granted = true;
          }
        }
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('otp_use_calendars_location', granted);
      setState(() {
        _useCalendarsLocation = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
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
                SwitchListTile(
                  title: const Text('Use contact\'s location'),
                  subtitle: const Text(
                    'Allow using your contacts\' addresses as locations. Requires contacts permission.',
                  ),
                  value: _useContactsLocation,
                  onChanged: (value) => _setUseContactsLocation(value),
                ),
                SwitchListTile(
                  title: const Text("Use upcoming events location"),
                  subtitle: const Text(
                      'Use the calendar as source of destinations. Requires calendars permissions.'),
                  value: _useCalendarsLocation,
                  onChanged: (value) => _setUseCalendarsLocation(value),
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
