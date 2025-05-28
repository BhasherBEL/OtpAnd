import 'package:otpand/objects/stop.dart';
import 'package:sqflite/sqflite.dart';
import '../helper.dart';

class StopDao {
  final dbHelper = DatabaseHelper();

  Future<void> batchInsert(List<Map<String, dynamic>> stops) async {
    if (stops.isEmpty) return;
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final stop in stops) {
      batch.insert('stops', stop, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insert(Map<String, dynamic> stop) async {
    final db = await dbHelper.database;
    await db.insert(
      'stops',
      stop,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchInsertDirection(List<Map<String, dynamic>> links) async {
    if (links.isEmpty) return;
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final link in links) {
      batch.insert(
        'direction_items',
        link,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertDirection(
    String stopId,
    String directionId,
    int order,
  ) async {
    final db = await dbHelper.database;
    await db.insert('direction_items', {
      'stop_gtfsId': stopId,
      'direction_id': directionId,
      'order': order,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Stop?> get(String gtfsId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'stops',
      where: 'gtfsId = ?',
      whereArgs: [gtfsId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Stop.parse(maps.first);
    }
    return null;
  }

  Future<List<Stop>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('stops');
    return Stop.parseAll(maps);
  }

  Future<int> delete(String gtfsId) async {
    final db = await dbHelper.database;
    return await db.delete('stops', where: 'gtfsId = ?', whereArgs: [gtfsId]);
  }

  Future<List<Stop>> getFromDirection(int directionId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT stops.*
      FROM stops
      JOIN direction_items ON stops.gtfsId = direction_items.stop_gtfsId
      WHERE direction_items.direction_id = ?
      ORDER BY direction_items."order"
      ''',
      [directionId],
    );
    return Stop.parseAll(maps);
  }
}
