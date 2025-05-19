import 'package:flutter/material.dart';

import 'package:otpand/objects/profile.dart';

class ProfilePage extends StatefulWidget {
  final Profile profile;
  final void Function(Profile)? onChanged;

  const ProfilePage({super.key, required this.profile, this.onChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  late String _selectedMode;

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

  final List<String> _modes = [
    'Transit',
    'Walk',
    'Bike',
    'Bike Park&Ride',
    'Car',
    'Car Par&Ride',
    'Car Kiss&Ride',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedColor = widget.profile.color;
    _selectedMode = widget.profile.mode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      children:
          _colorOptions.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        _selectedColor == color
                            ? Colors.black
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 18,
                  child:
                      _selectedColor == color
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Profile Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 32),
            const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              items:
                  _modes
                      .map(
                        (mode) =>
                            DropdownMenuItem(value: mode, child: Text(mode)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMode = value;
                  });
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final updatedProfile = widget.profile.copyWith(
                  name: _nameController.text,
                  color: _selectedColor,
                  mode: _selectedMode,
                );
                if (widget.onChanged != null) {
                  widget.onChanged!(updatedProfile);
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
                Navigator.of(context).pop(updatedProfile);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _selectedColor),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
