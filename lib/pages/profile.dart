import 'package:flutter/material.dart';
import 'package:otpand/db/crud/profiles.dart';
import 'package:otpand/objects/agency.dart';

import 'package:otpand/objects/profile.dart';
import 'package:otpand/pages/profile/card.dart';

class ProfilePage extends StatefulWidget {
  final Profile profile;

  const ProfilePage({super.key, required this.profile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  late bool avoidDirectWalking;
  late double walkPreference;
  late double walkSafetyPreference;
  late double walkSpeed;

  late bool transit;
  late double transitPreference;
  late double transitWaitReluctance;
  late double transitTransferWorth;
  late int transitMinimalTransferTime;
  late bool wheelchairAccessible;

  late bool bike;
  late double bikePreference;
  late double bikeFlatnessPreference;
  late double bikeSafetyPreference;
  late double bikeSpeed;
  late bool bikeFriendly;
  late bool bikeParkRide;

  late bool car;
  late double carPreference;
  late bool carParkRide;
  late bool carKissRide;
  late bool carPickup;

  late Map<Agency, bool> agenciesEnabled;

  late bool enableModeBus;
  late double preferenceModeBus;
  late bool enableModeMetro;
  late double preferenceModeMetro;
  late bool enableModeTram;
  late double preferenceModeTram;
  late bool enableModeTrain;
  late double preferenceModeTrain;
  late bool enableModeFerry;
  late double preferenceModeFerry;

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

    avoidDirectWalking = widget.profile.avoidDirectWalking;
    walkPreference = widget.profile.walkPreference;
    walkSafetyPreference = widget.profile.walkSafetyPreference;
    walkSpeed = widget.profile.walkSpeed;

    transit = widget.profile.transit;
    transitPreference = widget.profile.transitPreference;
    transitWaitReluctance = widget.profile.transitWaitReluctance;
    transitTransferWorth = widget.profile.transitTransferWorth;
    transitMinimalTransferTime = widget.profile.transitMinimalTransferTime;
    wheelchairAccessible = widget.profile.wheelchairAccessible;

    bike = widget.profile.bike;
    bikePreference = widget.profile.bikePreference;
    bikeFlatnessPreference = widget.profile.bikeFlatnessPreference;
    bikeSafetyPreference = widget.profile.bikeSafetyPreference;
    bikeSpeed = widget.profile.bikeSpeed;
    bikeFriendly = widget.profile.bikeFriendly;
    bikeParkRide = widget.profile.bikeParkRide;

    car = widget.profile.car;
    carPreference = widget.profile.carPreference;
    carParkRide = widget.profile.carParkRide;
    carKissRide = widget.profile.carKissRide;
    carPickup = widget.profile.carPickup;

    enableModeBus = widget.profile.enableModeBus;
    preferenceModeBus = widget.profile.preferenceModeBus;
    enableModeMetro = widget.profile.enableModeMetro;
    preferenceModeMetro = widget.profile.preferenceModeMetro;
    enableModeTram = widget.profile.enableModeTram;
    preferenceModeTram = widget.profile.preferenceModeTram;
    enableModeTrain = widget.profile.enableModeTrain;
    preferenceModeTrain = widget.profile.preferenceModeTrain;
    enableModeFerry = widget.profile.enableModeFerry;
    preferenceModeFerry = widget.profile.preferenceModeFerry;

    agenciesEnabled = widget.profile.agenciesEnabled;
    ensureAgencies();
    Agency.currentAgencies.addListener(ensureAgencies);
  }

  void ensureAgencies() {
    for (Agency agency in Agency.currentAgencies.value) {
      if (!agenciesEnabled.containsKey(agency)) {
        agenciesEnabled[agency] = true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      children: _colorOptions.map((color) {
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
      // contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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

  void _applyCurrentValuesToProfile() {
    widget.profile.name = _nameController.text;
    widget.profile.color = _selectedColor;
    widget.profile.avoidDirectWalking = avoidDirectWalking;
    widget.profile.walkPreference = walkPreference;
    widget.profile.walkSafetyPreference = walkSafetyPreference;
    widget.profile.walkSpeed = walkSpeed;
    widget.profile.transit = transit;
    widget.profile.transitPreference = transitPreference;
    widget.profile.transitWaitReluctance = transitWaitReluctance;
    widget.profile.transitTransferWorth = transitTransferWorth;
    widget.profile.transitMinimalTransferTime = transitMinimalTransferTime;
    widget.profile.wheelchairAccessible = wheelchairAccessible;
    widget.profile.bike = bike;
    widget.profile.bikePreference = bikePreference;
    widget.profile.bikeFlatnessPreference = bikeFlatnessPreference;
    widget.profile.bikeSafetyPreference = bikeSafetyPreference;
    widget.profile.bikeSpeed = bikeSpeed;
    widget.profile.bikeFriendly = bikeFriendly;
    widget.profile.bikeParkRide = bikeParkRide;
    widget.profile.car = car;
    widget.profile.carPreference = carPreference;
    widget.profile.carParkRide = carParkRide;
    widget.profile.carKissRide = carKissRide;
    widget.profile.carPickup = carPickup;
    widget.profile.agenciesEnabled = agenciesEnabled;
    widget.profile.enableModeBus = enableModeBus;
    widget.profile.preferenceModeBus = preferenceModeBus;
    widget.profile.enableModeMetro = enableModeMetro;
    widget.profile.preferenceModeMetro = preferenceModeMetro;
    widget.profile.enableModeTram = enableModeTram;
    widget.profile.preferenceModeTram = preferenceModeTram;
    widget.profile.enableModeTrain = enableModeTrain;
    widget.profile.preferenceModeTrain = preferenceModeTrain;
    widget.profile.enableModeFerry = enableModeFerry;
    widget.profile.preferenceModeFerry = preferenceModeFerry;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
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
            const SizedBox(height: 24),

            // Accessibility
            _buildSwitchTile(
              title: 'Wheelchair accessible',
              description: 'Prefer only wheelchair accessible routes.',
              value: wheelchairAccessible,
              onChanged: (v) => setState(() => wheelchairAccessible = v),
            ),
            const Divider(),

            // Walk
            const Text(
              'Walking',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildSwitchTile(
              title: 'Avoid direct walking',
              description:
                  'Avoid routes that require walking directly to the destination.',
              value: avoidDirectWalking,
              onChanged: (v) => setState(() => avoidDirectWalking = v),
            ),
            _buildSliderTile(
              title: 'Walk preference',
              description: 'How much you prefer walking over other modes.',
              value: walkPreference,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (v) => setState(() => walkPreference = v),
            ),
            _buildSliderTile(
              title: 'Walk safety preference',
              description: 'How much you value safe walking routes.',
              value: walkSafetyPreference,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (v) => setState(() => walkSafetyPreference = v),
            ),
            _buildSliderTile(
              title: 'Walk speed',
              description: 'Your average walking speed (km/h).',
              value: walkSpeed,
              min: 2.0,
              max: 10.0,
              divisions: 16,
              onChanged: (v) => setState(() => walkSpeed = v),
              valueSuffix: 'km/h',
            ),
            const Divider(),

            // Transit
            const Text(
              'Transit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ProfileCardWidget(
                title: 'Enable transit',
                description: 'Allow using public transport.',
                initialState: transit,
                onStateChanged: (v) => setState(() => transit = v),
                hasBorder: true,
                children: [
                  _buildSliderTile(
                    title: 'Transit preference',
                    description:
                        'How much you prefer transit over other modes.',
                    value: transitPreference,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    onChanged: (v) => setState(() => transitPreference = v),
                  ),
                  _buildSliderTile(
                    title: 'Transit wait reluctance',
                    description: 'How much you dislike waiting for transit.',
                    value: transitWaitReluctance,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    onChanged: (v) => setState(() => transitWaitReluctance = v),
                  ),
                  _buildSliderTile(
                    title: 'Transit transfer worth',
                    description: 'How much a transfer is worth in minutes.',
                    value: transitTransferWorth,
                    min: 0.0,
                    max: 15.0,
                    divisions: 15,
                    onChanged: (v) => setState(() => transitTransferWorth = v),
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
                                ? () => setState(
                                      () => transitMinimalTransferTime -= 1,
                                    )
                                : null,
                          ),
                          Text('$transitMinimalTransferTime m'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: transitMinimalTransferTime < 60
                                ? () => setState(
                                      () => transitMinimalTransferTime += 1,
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
                    onStateChanged: (v) => setState(() => enableModeBus = v),
                    children: [
                      _buildSliderTile(
                        title: 'Preference for bus',
                        value: preferenceModeBus,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        onChanged: (v) => setState(() => preferenceModeBus = v),
                      ),
                    ],
                  ),
                  ProfileCardWidget(
                    title: 'Tram',
                    initialState: enableModeTram,
                    onStateChanged: (v) => setState(() => enableModeTram = v),
                    children: [
                      _buildSliderTile(
                        title: 'Preference for tram',
                        value: preferenceModeTram,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        onChanged: (v) =>
                            setState(() => preferenceModeTram = v),
                      ),
                    ],
                  ),
                  ProfileCardWidget(
                    title: 'Metro',
                    initialState: enableModeMetro,
                    onStateChanged: (v) => setState(() => enableModeMetro = v),
                    children: [
                      _buildSliderTile(
                        title: 'Preference for metro',
                        value: preferenceModeMetro,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        onChanged: (v) =>
                            setState(() => preferenceModeMetro = v),
                      ),
                    ],
                  ),
                  ProfileCardWidget(
                    title: 'Train',
                    initialState: enableModeTrain,
                    onStateChanged: (v) => setState(() => enableModeTrain = v),
                    children: [
                      _buildSliderTile(
                        title: 'Preference for train',
                        value: preferenceModeTrain,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        onChanged: (v) =>
                            setState(() => preferenceModeTrain = v),
                      ),
                    ],
                  ),
                  ProfileCardWidget(
                    title: 'Ferry',
                    initialState: enableModeFerry,
                    onStateChanged: (v) => setState(() => enableModeFerry = v),
                    children: [
                      _buildSliderTile(
                        title: 'Preference for ferry',
                        value: preferenceModeFerry,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        onChanged: (v) =>
                            setState(() => preferenceModeFerry = v),
                      )
                    ],
                  ),
                ]),
            const Divider(),
            const Text(
              'Bicycle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildSwitchTile(
              title: 'Enable bicycle',
              description: 'Allow using a bicycle.',
              value: bike,
              onChanged: (v) => setState(() => bike = v),
            ),
            _buildSliderTile(
              title: 'Bike preference',
              description: 'How much you prefer biking over other modes.',
              value: bikePreference,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (v) => setState(() => bikePreference = v),
            ),
            _buildSliderTile(
              title: 'Bike flatness preference',
              description: 'How much you prefer flat routes.',
              value: bikeFlatnessPreference,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (v) => setState(() => bikeFlatnessPreference = v),
            ),
            _buildSliderTile(
              title: 'Bike safety preference',
              description: 'How much you value safe bike routes.',
              value: bikeSafetyPreference,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (v) => setState(() => bikeSafetyPreference = v),
            ),
            _buildSliderTile(
              title: 'Bike speed',
              description: 'Your average cycling speed (km/h).',
              value: bikeSpeed,
              min: 5.0,
              max: 40.0,
              divisions: 35,
              onChanged: (v) => setState(() => bikeSpeed = v),
              valueSuffix: 'km/h',
            ),
            _buildSwitchTile(
              title: 'Bike friendly',
              description: 'Prefer bike-friendly routes.',
              value: bikeFriendly,
              onChanged: (v) => setState(() => bikeFriendly = v),
            ),
            _buildSwitchTile(
              title: 'Bike park & ride',
              description: 'Allow parking your bike and continuing by transit.',
              value: bikeParkRide,
              onChanged: (v) => setState(() => bikeParkRide = v),
            ),
            const Divider(),

            // Car
            const Text('Car', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildSwitchTile(
              title: 'Enable car',
              description: 'Allow using a car.',
              value: car,
              onChanged: (v) => setState(() => car = v),
            ),
            _buildSliderTile(
              title: 'Car preference',
              description: 'How much you prefer driving over other modes.',
              value: carPreference,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (v) => setState(() => carPreference = v),
            ),
            _buildSwitchTile(
              title: 'Car park & ride',
              description: 'Allow parking your car and continuing by transit.',
              value: carParkRide,
              onChanged: (v) => setState(() => carParkRide = v),
            ),
            _buildSwitchTile(
              title: 'Car kiss & ride',
              description: 'Allow being dropped off by car at a stop.',
              value: carKissRide,
              onChanged: (v) => setState(() => carKissRide = v),
            ),
            _buildSwitchTile(
              title: 'Car pickup',
              description: 'Allow being picked up by car at your destination.',
              value: carPickup,
              onChanged: (v) => setState(() => carPickup = v),
            ),
            const Divider(),
            const Text(
              'Agencies',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...agenciesEnabled.entries.map((entry) {
              return CheckboxListTile(
                title: Text(entry.key.name ?? entry.key.gtfsId),
                value: entry.value,
                onChanged: (bool? value) {
                  setState(() {
                    agenciesEnabled[entry.key] = value ?? false;
                  });
                },
              );
            }),
            const SizedBox(height: 24),

            // Action buttons
            if (widget.profile.hasTemporaryEdits) ...[
              // For profiles with temporary edits
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
                        _applyCurrentValuesToProfile();
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
                    _applyCurrentValuesToProfile();
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
                  style: TextButton.styleFrom(
                    foregroundColor: _selectedColor,
                  ),
                ),
              ),
            ] else ...[
              // For profiles without temporary edits
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!widget.profile.hasTemporaryEdits) {
                          widget.profile.startTemporaryEditing();
                        }
                        _applyCurrentValuesToProfile();
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
                        _applyCurrentValuesToProfile();
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
