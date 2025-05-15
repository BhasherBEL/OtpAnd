import 'package:otpand/objects/stop.dart';
import 'package:sqflite/sqflite.dart';
import '../helper.dart';

class StopDao {
  final dbHelper = DatabaseHelper();

  Future<int> getOrInsert(Map<String, dynamic> stop) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'stops',
      where: 'otpId = ?',
      whereArgs: [stop['otpId']],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return await db.insert(
      'stops',
      stop,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insert(Map<String, dynamic> stop) async {
    final db = await dbHelper.database;
    return await db.insert(
      'stops',
      stop,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertRoute(int stopId, int routeId) async {
    final db = await dbHelper.database;
    return await db.insert('routes_stops', {
      'stop_id': stopId,
      'route_id': routeId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Stop?> get(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'stops',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Stop.parse(maps.first);
    }
    return null;
  }

  Future<Stop?> getByOtpId(String otpId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'stops',
      where: 'otpId = ?',
      whereArgs: [otpId],
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

  Future<int> delete(String id) async {
    final db = await dbHelper.database;
    return await db.delete('stops', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Stop>> getFromRoute(int routeId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT s.* FROM stops s
      INNER JOIN routes_stops sr ON s.id = sr.stop_id
      WHERE sr.route_id = ?
    ''',
      [routeId],
    );
    return Stop.parseAll(maps);
  }
}
