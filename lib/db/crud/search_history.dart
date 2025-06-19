import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:otpand/objects/search_history.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/profile.dart';
import 'package:sqflite/sqflite.dart';
import 'package:otpand/db/helper.dart';

class SearchHistoryDao {
  static final SearchHistoryDao _instance = SearchHistoryDao._internal();
  factory SearchHistoryDao() => _instance;
  SearchHistoryDao._internal();

  final dbHelper = DatabaseHelper();

  
  Future<int> insert(SearchHistory history) async {
    try {
      final db = await dbHelper.database;
      final id = await db.insert(
        'search_history',
        history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      
      final updatedHistory = history.copyWith(id: id);
      final currentList = List<SearchHistory>.from(SearchHistory.currentHistory.value);
      currentList.insert(0, updatedHistory);
      
      
      if (currentList.length > 50) {
        currentList.removeRange(50, currentList.length);
      }
      
      SearchHistory.currentHistory.value = currentList;
      
      
      if (currentList.length >= 50) {
        unawaited(_cleanupOldEntries());
      }
      
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting search history: $e');
      }
      rethrow;
    }
  }

  
  Future<void> _cleanupOldEntries() async {
    try {
      await deleteOldEntries(keepCount: 100);
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old entries: $e');
      }
    }
  }

  /// Save a new search with deduplication
  Future<int> saveSearch({
    required Location fromLocation,
    required Location toLocation,
    required Profile profile,
    required String timeType,
    DateTime? selectedDateTime,
  }) async {
    
    final currentList = SearchHistory.currentHistory.value;
    if (currentList.isNotEmpty) {
      final latest = currentList.first;
      if (_isDuplicateSearch(latest, fromLocation, toLocation, profile, timeType)) {
        
        return latest.id ?? 0;
      }
    }

    final history = SearchHistory.fromSearch(
      fromLocation: fromLocation,
      toLocation: toLocation,
      profile: profile,
      timeType: timeType,
      selectedDateTime: selectedDateTime,
    );
    return await insert(history);
  }

  
  bool _isDuplicateSearch(
    SearchHistory latest,
    Location fromLocation,
    Location toLocation,
    Profile profile,
    String timeType,
  ) {
    return latest.fromLocationLat == fromLocation.lat &&
        latest.fromLocationLon == fromLocation.lon &&
        latest.toLocationLat == toLocation.lat &&
        latest.toLocationLon == toLocation.lon &&
        latest.profileId == profile.id &&
        latest.timeType == timeType;
  }

  Future<void> update(SearchHistory history) async {
    if (history.id == null) return;
    try {
      final db = await dbHelper.database;
      await db.update(
        'search_history',
        history.toMap(),
        where: 'id = ?',
        whereArgs: [history.id],
      );
      
      
      final currentList = List<SearchHistory>.from(SearchHistory.currentHistory.value);
      final index = currentList.indexWhere((h) => h.id == history.id);
      if (index != -1) {
        currentList[index] = history;
        SearchHistory.currentHistory.value = currentList;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating search history: $e');
      }
      rethrow;
    }
  }

  Future<SearchHistory?> get(int id) async {
    try {
      final db = await dbHelper.database;
      final maps = await db.query(
        'search_history',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return SearchHistory.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting search history by id: $e');
      }
      return null;
    }
  }

  Future<SearchHistory?> getLatest() async {
    final history = SearchHistory.currentHistory.value;
    if (history.isNotEmpty) {
      return history.first;
    }
    return null;
  }

  Future<List<SearchHistory>> getAll({int limit = 50}) async {
    try {
      final db = await dbHelper.database;
      final maps = await db.query(
        'search_history',
        orderBy: 'searchedAt DESC',
        limit: limit,
      );
      return SearchHistory.parseAll(maps);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all search history: $e');
      }
      return [];
    }
  }

  Future<void> loadAll() async {
    try {
      final history = await getAll(limit: 50);
      SearchHistory.currentHistory.value = history;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading search history: $e');
      }
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await dbHelper.database;
      final result = await db.delete(
        'search_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Update in-memory list efficiently
      final currentList = List<SearchHistory>.from(SearchHistory.currentHistory.value);
      currentList.removeWhere((h) => h.id == id);
      SearchHistory.currentHistory.value = currentList;
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting search history: $e');
      }
      return 0;
    }
  }

  Future<void> deleteAll() async {
    try {
      final db = await dbHelper.database;
      await db.delete('search_history');
      SearchHistory.currentHistory.value = [];
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all search history: $e');
      }
    }
  }

  Future<void> deleteOldEntries({int keepCount = 100}) async {
    try {
      final db = await dbHelper.database;
      await db.execute('''
        DELETE FROM search_history 
        WHERE id NOT IN (
          SELECT id FROM search_history 
          ORDER BY searchedAt DESC 
          LIMIT ?
        )
      ''', [keepCount]);
      
      
      await loadAll();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting old search history entries: $e');
      }
    }
  }
}

