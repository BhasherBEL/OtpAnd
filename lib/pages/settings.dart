import 'dart:async';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:otpand/api/gtfs.dart';
import 'package:otpand/db/helper.dart';
import 'package:otpand/objects/config.dart';
import 'package:otpand/pages/otpconfig.dart';
import 'package:otpand/pages/profiles.dart';
import 'package:otpand/utils/import_export_service.dart';

import 'package:otpand/utils/gnss.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _sortStopsByDistance = Config().sortStopsByDistance;
  bool _useContactsLocation = Config().useContactsLocation;
  bool _useCalendarsLocation = Config().useCalendarsLocation;

  Future<void> _setSortStopsByDistance(bool value) async {
    if (value) {
      bool gpsAvailable = false;
      try {
        final loc = await getCurrentLocation();
        gpsAvailable = loc != null;
      } on TimeoutException catch (_) {
        gpsAvailable = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS access timed out. Please try again.'),
            ),
          );
        }
      } on LocationServiceDisabledException catch (_) {
        gpsAvailable = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS is disabled. Please enable it in settings.'),
            ),
          );
        }
      } on PermissionDeniedException catch (_) {
        gpsAvailable = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'GPS permission denied. Please allow it in settings.',
              ),
            ),
          );
        }
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
    if (await Config().setValue(ConfigKey.sortStopsByDistance, value)) {
      setState(() {
        _sortStopsByDistance = value;
      });
    }
  }

  Future<void> _setUseContactsLocation(bool value) async {
    if (value) {
      bool granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Contacts permission is required to use contact\'s location.',
              ),
            ),
          );
        }
        return;
      }
    }
    if (await Config().setValue(ConfigKey.useContactsLocation, value)) {
      setState(() {
        _useContactsLocation = value;
      });
    }
  }

  Future<void> _setUseCalendarsLocation(bool value) async {
    if (value) {
      bool granted = false;
      final calendarPlugin = DeviceCalendarPlugin();
      try {
        var permissionGranted = await calendarPlugin.hasPermissions();
        if (permissionGranted.isSuccess && permissionGranted.data == true) {
          granted = true;
        } else {
          permissionGranted = await calendarPlugin.requestPermissions();
          if (permissionGranted.isSuccess &&
              permissionGranted.data != null &&
              permissionGranted.data == true) {
            granted = true;
          }
        }
      } on Exception catch (e, s) {
        debugPrintStack(
          stackTrace: s,
          label: 'Error requesting calendar permissions: $e',
        );
      }
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Calendar permission is required to use upcoming events location.',
              ),
            ),
          );
        }
        return;
      }
    }
    if (await Config().setValue(ConfigKey.useCalendarsLocation, value)) {
      setState(() {
        _useCalendarsLocation = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
            title: const Text('Use upcoming events location'),
            subtitle: const Text(
              'Use the calendar as source of destinations. Requires calendars permissions.',
            ),
            value: _useCalendarsLocation,
            onChanged: (value) => _setUseCalendarsLocation(value),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profiles'),
            subtitle: const Text('Manage your travel profiles'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ProfilesPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: const Text('OTP Configuration'),
            subtitle: const Text('Configure your OpenTripPlanner instance'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const OtpConfigPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Force GTFS cleanup and download'),
            onTap: () async {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting GTFS cleanup...')),
                );
              }

              final db = await DatabaseHelper().database;
              await db.delete('direction_items');
              await db.delete('directions');
              await db.delete('agencies_routes');
              await db.delete('routes');
              await db.delete('stops');
              await db.delete('agencies');

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('GTFS cleanup Done. Starting download...')),
                );
              }

              await checkAndSyncGtfsData(force: true);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GTFS data download completed successfully!'),
                  ),
                );
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Data Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Settings & Data'),
            subtitle:
                const Text('Export all settings, profiles, and favorites'),
            onTap: () async {
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting data...')),
                  );
                }

                final filePath =
                    await ImportExportService.exportDataWithFilePicker();

                if (context.mounted) {
                  if (filePath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Data exported successfully to: $filePath'),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export cancelled')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Settings & Data'),
            subtitle: const Text(
                'Import settings, profiles, and favorites from file'),
            onTap: () async {
              try {
                final filePath = await ImportExportService.pickImportFile();

                if (filePath != null) {
                  // Show confirmation dialog with import info
                  final importInfo =
                      await ImportExportService.getExportInfo(filePath);

                  if (context.mounted) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Import Data'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'This will replace all current data with:'),
                            const SizedBox(height: 8),
                            Text('• ${importInfo['profilesCount']} profiles'),
                            Text(
                                '• ${importInfo['favouritesCount']} favorites'),
                            Text(
                                '• ${importInfo['historyCount']} search history entries'),
                            const SizedBox(height: 8),
                            Text(
                                'Exported: ${DateTime.parse(importInfo['exportedAt'] as String).toLocal()}'),
                            const SizedBox(height: 12),
                            const Text(
                              'WARNING: This cannot be undone. Consider exporting your current data first.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Import'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Importing data...')),
                      );

                      await ImportExportService.importData(filePath);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data imported successfully!'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
          )
        ],
      ),
    );
  }
}
