import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/db/helper.dart';

class ProfileDao {
  static const String table = 'profiles';

  static Future<Profile> newProfile() async {
    final db = await DatabaseHelper().database;
    final id = await db.insert(table, {
      'id': 0,
      'name': 'New profile',
      'color': Colors.blue.value,
      'avoidDirectWalking': 0,
      'walkPreference': 1.0, // 0.1 - 2
      'walkSafetyPreference': 0.5, // 0 - 1
      'walkSpeed': 5.0, // 2 - 10
      'transit': 1,
      'transitPreference': 1.0, // 0.1 - 2
      'transitWaitReluctance': 1.0, // 0.1 - 2
      'transitTransferWorth': 0.0, // 0 - 15
      'transitMinimalTransferTime': 1, // 0 - 60
      'wheelchairAccessible': 0,
      'bike': 0,
      'bikePreference': 1.0, // 0.1 - 2
      'bikeFlatnessPreference': 0.5, // 0 - 1
      'bikeSafetyPreference': 0.5, // 0 - 1
      'bikeSpeed': 15.0, // 5 - 40
      'bikeFriendly': 0,
      'bikeParkRide': 0,
      'car': 0,
      'carPreference': 1.0, // 0.1 - 2
      'carParkRide': 0,
      'carKissRide': 0,
      'carPickup': 0,
    });
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Profile.parse(maps.first);
    } else {
      throw Exception('Failed to create new profile');
    }
  }

  static Future<int> insert(Profile profile) async {
    final db = await DatabaseHelper().database;
    return await db.insert(table, profile.toMap());
  }

  static Future<List<Profile>> getAll() async {
    final db = await DatabaseHelper().database;
    final maps = await db.query(table);
    return Profile.parseAll(maps);
  }

  static Future<Profile?> getById(int id) async {
    final db = await DatabaseHelper().database;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Profile.parse(maps.first);
    }
    return null;
  }

  static Future<int> update(int id, Profile profile) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      table,
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> delete(int id) async {
    final db = await DatabaseHelper().database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // Ensure at least one profile exists (create new on first startup)
  static Future<void> ensureBlankProfile() async {
    final db = await DatabaseHelper().database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table'),
    );
    if (count == 0) {
      await newProfile();
    }
  }
}
