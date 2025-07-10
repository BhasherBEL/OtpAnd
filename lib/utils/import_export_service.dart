import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:otpand/objects/config.dart';
import 'package:otpand/db/crud/profiles.dart';
import 'package:otpand/db/crud/favourites.dart';
import 'package:otpand/db/crud/search_history.dart';
import 'package:otpand/db/helper.dart';

class ImportExportService {
  static const String _exportVersion = '1.0.0';

  /// Export all user data to a JSON file
  static Future<String> exportData() async {
    try {
      // Get all data
      final settings = await _exportSettings();
      final profiles = await _exportProfiles();
      final favourites = await _exportFavourites();
      final searchHistory = await _exportSearchHistory();

      // Create export data structure
      final exportData = {
        'version': _exportVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings,
        'profiles': profiles,
        'favourites': favourites,
        'searchHistory': searchHistory,
      };

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'otpand_export_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      return file.path;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  /// Import data from a JSON file
  static Future<void> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Import file does not exist');
      }

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;

      // Validate export version
      final version = data['version'] as String?;
      if (version != _exportVersion) {
        throw Exception('Unsupported export version: $version');
      }

      // Import data in order (settings first, then profiles, then dependent data)
      await _importSettings(data['settings'] as Map<String, dynamic>?);
      await _importProfiles(data['profiles'] as List<dynamic>?);
      await _importFavourites(data['favourites'] as List<dynamic>?);
      await _importSearchHistory(data['searchHistory'] as List<dynamic>?);

      // Reload data in memory
      await _reloadDataInMemory();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  /// Export settings from SharedPreferences
  static Future<Map<String, dynamic>> _exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, dynamic>{};

    for (final configKey in ConfigKey.values) {
      final value = prefs.get(configKey.key);
      if (value != null) {
        settings[configKey.key] = value;
      }
    }

    return settings;
  }

  /// Export all profiles
  static Future<List<Map<String, dynamic>>> _exportProfiles() async {
    final profiles = await ProfileDao.getAll();
    return profiles.map((profile) {
      final map = profile.toMap();
      // Remove temporary editing fields from export
      map.remove('hasTemporaryEdits');
      map.remove('originalValues');
      return map;
    }).toList();
  }

  /// Export all favourites
  static Future<List<Map<String, dynamic>>> _exportFavourites() async {
    final db = await DatabaseHelper().database;
    final maps = await db.query('favourites');
    return maps.cast<Map<String, dynamic>>();
  }

  /// Export search history
  static Future<List<Map<String, dynamic>>> _exportSearchHistory() async {
    final db = await DatabaseHelper().database;
    final maps = await db.query('search_history', orderBy: 'searchedAt DESC');
    return maps.cast<Map<String, dynamic>>();
  }

  /// Import settings to SharedPreferences
  static Future<void> _importSettings(Map<String, dynamic>? settings) async {
    if (settings == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;

      // Find the corresponding ConfigKey
      final configKey = ConfigKey.values.where((k) => k.key == key).firstOrNull;
      if (configKey == null) {
        debugPrint('Unknown config key during import: $key');
        continue;
      }

      // Set the value with proper type
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }

    // Reload config in memory
    await Config().init();
  }

  /// Import profiles
  static Future<void> _importProfiles(List<dynamic>? profiles) async {
    if (profiles == null) return;

    final db = await DatabaseHelper().database;

    // Clear existing profiles
    await db.delete('profiles');

    // Insert imported profiles
    for (final profileData in profiles) {
      if (profileData is Map<String, dynamic>) {
        await db.insert('profiles', profileData);
      }
    }
  }

  /// Import favourites
  static Future<void> _importFavourites(List<dynamic>? favourites) async {
    if (favourites == null) return;

    final db = await DatabaseHelper().database;

    // Clear existing favourites
    await db.delete('favourites');

    // Insert imported favourites
    for (final favouriteData in favourites) {
      if (favouriteData is Map<String, dynamic>) {
        await db.insert('favourites', favouriteData);
      }
    }
  }

  /// Import search history
  static Future<void> _importSearchHistory(List<dynamic>? searchHistory) async {
    if (searchHistory == null) return;

    final db = await DatabaseHelper().database;

    // Clear existing search history
    await db.delete('search_history');

    // Insert imported search history
    for (final historyData in searchHistory) {
      if (historyData is Map<String, dynamic>) {
        await db.insert('search_history', historyData);
      }
    }
  }

  /// Reload all data in memory after import
  static Future<void> _reloadDataInMemory() async {
    // Reload favourites
    await FavouriteDao().loadAll();
    
    // Reload search history
    await SearchHistoryDao().loadAll();
  }

  /// Get export file info for display
  static Future<Map<String, dynamic>> getExportInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;

      final profilesCount = (data['profiles'] as List<dynamic>?)?.length ?? 0;
      final favouritesCount = (data['favourites'] as List<dynamic>?)?.length ?? 0;
      final historyCount = (data['searchHistory'] as List<dynamic>?)?.length ?? 0;

      return {
        'version': data['version'],
        'exportedAt': data['exportedAt'],
        'profilesCount': profilesCount,
        'favouritesCount': favouritesCount,
        'historyCount': historyCount,
      };
    } on Exception catch (e) {
      debugPrint('Error reading export info: $e');
      rethrow;
    }
  }

  /// Show file picker for import
  static Future<String?> pickImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select OTPAnd Export File',
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Error picking import file: $e');
      return null;
    }
  }

  /// Export data and save to Downloads folder with file picker
  static Future<String?> exportDataWithFilePicker() async {
    try {
      // Create export data
      final settings = await _exportSettings();
      final profiles = await _exportProfiles();
      final favourites = await _exportFavourites();
      final searchHistory = await _exportSearchHistory();

      final exportData = {
        'version': _exportVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings,
        'profiles': profiles,
        'favourites': favourites,
        'searchHistory': searchHistory,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Convert string to bytes for mobile platforms
      final bytes = utf8.encode(jsonString);
      
      // Use file picker to save
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'otpand_export_$timestamp.json';
      
      final filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save OTPAnd Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      return filePath;
    } catch (e) {
      debugPrint('Error exporting data with file picker: $e');
      rethrow;
    }
  }
}

