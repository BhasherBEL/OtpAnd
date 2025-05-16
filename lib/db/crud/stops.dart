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

  Future<void> batchInsertRoutes(List<Map<String, String>> links) async {
    if (links.isEmpty) return;
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final link in links) {
      batch.insert(
        'routes_stops',
        link,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertRoute(String stopId, String routeId) async {
    final db = await dbHelper.database;
    await db.insert('routes_stops', {
      'stop_id': stopId,
      'route_id': routeId,
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

  Future<List<Stop>> getFromRoute(String routeId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT s.* FROM stops s
      INNER JOIN routes_stops sr ON s.gtfsId = sr.stop_id
      WHERE sr.route_id = ?
    ''',
      [routeId],
    );
    return Stop.parseAll(maps);
  }
}
