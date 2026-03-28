import 'package:flutter/material.dart';
import 'package:otpand/api/maas_health.dart';
import 'package:otpand/objects/config.dart';

class OtpConfigPage extends StatefulWidget {
  const OtpConfigPage({super.key});

  @override
  State<OtpConfigPage> createState() => _OtpConfigPageState();
}

class _OtpConfigPageState extends State<OtpConfigPage> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  MaasHealthResult? _healthResult;

  @override
  void initState() {
    super.initState();
    _urlController.text = Config().maasUrl;
  }

  Future<void> _saveConfig() async {
    final success = await Config().setValue(
      ConfigKey.maasUrl,
      _urlController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Configuration saved' : 'Failed to save configuration',
          ),
        ),
      );
    }
    // Clear previous result when URL changes
    setState(() => _healthResult = null);
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    setState(() {
      _isTesting = true;
      _healthResult = null;
    });
    final result = await checkMaasHealth(url);
    if (mounted) {
      setState(() {
        _isTesting = false;
        _healthResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('maas-rs Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Backend URL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'maas-rs URL',
                hintText: 'http://192.168.0.211:3000',
                helperText: 'Base URL of the maas-rs routing backend (no trailing slash).',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() => _healthResult = null),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: Text(_isTesting ? 'Testing…' : 'Test connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
            if (_healthResult != null) ...[
              const SizedBox(height: 20),
              _HealthResultCard(result: _healthResult!),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

class _HealthResultCard extends StatelessWidget {
  const _HealthResultCard({required this.result});

  final MaasHealthResult result;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (result.status) {
      MaasHealthStatus.ok => (Colors.green, Icons.check_circle),
      MaasHealthStatus.timeout => (Colors.red, Icons.timer_off),
      MaasHealthStatus.unreachable => (Colors.red, Icons.cloud_off),
      MaasHealthStatus.httpError => (Colors.orange, Icons.http),
      MaasHealthStatus.notGraphQL => (Colors.orange, Icons.code_off),
      MaasHealthStatus.incompatible => (Colors.orange, Icons.warning_amber),
      MaasHealthStatus.graphqlError => (Colors.orange, Icons.error_outline),
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ),
                if (result.latency != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(100)),
                    ),
                    child: Text(
                      '${result.latency!.inMilliseconds} ms',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.message,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            if (result.httpStatusCode != null &&
                result.status != MaasHealthStatus.ok) ...[
              const SizedBox(height: 8),
              Text(
                'HTTP status: ${result.httpStatusCode}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
