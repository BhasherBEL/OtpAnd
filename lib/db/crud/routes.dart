import 'package:otpand/objects/route.dart';
import 'package:sqflite/sqflite.dart';
import '../helper.dart';

class RouteDao {
  final dbHelper = DatabaseHelper();

  Future<int> getOrInsert(Map<String, dynamic> route) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'routes',
      where: 'otpId = ?',
      whereArgs: [route['otpId']],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return await db.insert(
      'routes',
      route,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insert(Map<String, dynamic> route) async {
    final db = await dbHelper.database;
    return await db.insert(
      'routes',
      route,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertAgency(int routeId, int agencyId) async {
    final db = await dbHelper.database;
    return await db.insert('agencies_routes', {
      'route_id': routeId,
      'agency_id': agencyId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<RouteInfo?> get(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return RouteInfo.parse(maps.first);
    }
    return null;
  }

  Future<RouteInfo?> getByOtpId(String otpId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'routes',
      where: 'otpId = ?',
      whereArgs: [otpId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return RouteInfo.parse(maps.first);
    }
    return null;
  }

  Future<List<RouteInfo>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('routes');
    return RouteInfo.parseAll(maps);
  }

  Future<int> delete(String id) async {
    final db = await dbHelper.database;
    return await db.delete('routes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RouteInfo>> getFromAgency(int agencyId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT r.* FROM routes r
      INNER JOIN agencies_routes ar ON r.id = ar.route_id
      WHERE ar.agency_id = ?
    ''',
      [agencyId],
    );
    return RouteInfo.parseAll(maps);
  }

  Future<List<RouteInfo>> getFromStop(int stopId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT r.* FROM routes r
      INNER JOIN routes_stops sr ON r.id = sr.route_id
      WHERE sr.stop_id = ?
    ''',
      [stopId],
    );
    return RouteInfo.parseAll(maps);
  }
}
