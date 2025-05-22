import 'package:flutter/material.dart';
import 'package:otpand/pages/otpconfig.dart';
import 'package:otpand/pages/profiles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profiles'),
            subtitle: const Text('Manage your travel profiles'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: const Text('OTP Configuration'),
            subtitle: const Text('Configure your OpenTripPlanner instance'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OtpConfigPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
