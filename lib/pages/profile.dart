import 'package:flutter/material.dart';
import 'package:otpand/db/crud/profiles.dart';
import 'package:otpand/objects/agency.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/pages/profile/walking_page.dart';
import 'package:otpand/pages/profile/transit_page.dart';
import 'package:otpand/pages/profile/bicycle_page.dart';
import 'package:otpand/pages/profile/car_page.dart';
import 'package:otpand/pages/profile/agency_page.dart';

class ProfilePage extends StatefulWidget {
  final Profile profile;

  const ProfilePage({super.key, required this.profile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.amber,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedColor = widget.profile.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyBasicSettings() {
    widget.profile.name = _nameController.text;
    widget.profile.color = _selectedColor;
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      children: _colorOptions.map((color) {
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    _selectedColor == color ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: color,
              radius: 18,
              child: _selectedColor == color
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: enabled
              ? _selectedColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            icon,
            color: enabled ? _selectedColor : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: enabled ? null : Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Profile Color',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildColorPicker(),
                  const SizedBox(height: 32),
                  _buildSettingsCard(
                    title: 'Walking',
                    description: 'Configure walking preferences and speed',
                    icon: Icons.directions_walk,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              WalkingSettingsPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Transit',
                    description:
                        'Public transport settings and mode preferences',
                    icon: Icons.directions_bus,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              TransitSettingsPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Bicycle',
                    description: 'Cycling preferences and route options',
                    icon: Icons.directions_bike,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              BicycleSettingsPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Car',
                    description: 'Driving preferences and park & ride options',
                    icon: Icons.directions_car,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              CarSettingsPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Agencies',
                    description: 'Select which transit agencies to use',
                    icon: Icons.business,
                    enabled: widget.profile.agenciesEnabled.isNotEmpty,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AgencySettingsPage(profile: widget.profile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (widget.profile.hasTemporaryEdits) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        widget.profile.revertToOriginal();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Reverted to original!')),
                          );
                          Navigator.of(context).pop(widget.profile);
                        }
                      },
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Revert'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        _applyBasicSettings();
                        widget.profile.commitTemporaryEdits();
                        await ProfileDao.update(
                            widget.profile.id, widget.profile);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Profile saved permanently!')),
                          );
                          Navigator.of(context).pop(widget.profile);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    _applyBasicSettings();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Continuing with temporary changes!')),
                      );
                      Navigator.of(context).pop(widget.profile);
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Continue with these settings'),
                  style: TextButton.styleFrom(foregroundColor: _selectedColor),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!widget.profile.hasTemporaryEdits) {
                          widget.profile.startTemporaryEditing();
                        }
                        _applyBasicSettings();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Temporary changes applied!')),
                          );
                          Navigator.of(context).pop(widget.profile);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Use Temporarily'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        _applyBasicSettings();
                        await ProfileDao.update(
                            widget.profile.id, widget.profile);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile saved!')),
                          );
                          Navigator.of(context).pop(widget.profile);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save'),
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
