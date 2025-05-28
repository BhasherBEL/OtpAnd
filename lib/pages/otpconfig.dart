import 'package:flutter/material.dart';
import 'package:otpand/objects/config.dart';

class OtpConfigPage extends StatefulWidget {
  const OtpConfigPage({super.key});

  @override
  State<OtpConfigPage> createState() => _OtpConfigPageState();
}

class _OtpConfigPageState extends State<OtpConfigPage> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = Config();

    _urlController.text = config.otpUrl;
    _usernameController.text = config.otpUsername;
    _passwordController.text = config.otpPassword;
    _countryController.text = config.otpCountry;
  }

  Future<void> _saveConfig() async {
    final config = Config();

    final success = await config.setValues({
      ConfigKey.otpUrl: _urlController.text.trim(),
      ConfigKey.otpUsername: _usernameController.text.trim(),
      ConfigKey.otpPassword: _passwordController.text.trim(),
      ConfigKey.otpCountry: _countryController.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'OTP configuration saved'
                : 'Failed to save OTP configuration',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Connection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'OpenTripPlanner URL',
                hintText: 'https://otp.example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            const Text(
              'Authentication',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            const Text('Other', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                hintText: 'e.g. be',
                helperText:
                    'Used for address resolving. Multiple values can be used, separated by a comma.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveConfig,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
