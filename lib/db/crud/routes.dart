import 'package:otpand/objects/route.dart';
import 'package:sqflite/sqflite.dart';
import '../helper.dart';

class RouteDao {
  final dbHelper = DatabaseHelper();

  Future<void> batchInsert(List<Map<String, dynamic>> routes) async {
    if (routes.isEmpty) return;
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final route in routes) {
      batch.insert(
        'routes',
        route,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insert(Map<String, dynamic> route) async {
    final db = await dbHelper.database;
    await db.insert(
      'routes',
      route,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchInsertAgencies(List<Map<String, String>> links) async {
    if (links.isEmpty) return;
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final link in links) {
      batch.insert(
        'agencies_routes',
        link,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertAgency(String routeId, String agencyId) async {
    final db = await dbHelper.database;
    await db.insert('agencies_routes', {
      'route_gtfsId': routeId,
      'agency_gtfsId': agencyId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<RouteInfo?> get(String gtfsId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'routes',
      where: 'gtfsId = ?',
      whereArgs: [gtfsId],
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

  Future<int> delete(String gtfsId) async {
    final db = await dbHelper.database;
    return await db.delete('routes', where: 'gtfsId = ?', whereArgs: [gtfsId]);
  }

  Future<List<RouteInfo>> getFromAgency(String agencyId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT r.* FROM routes r
      INNER JOIN agencies_routes ar ON r.gtfsId = ar.route_gtfsId
      WHERE ar.agency_gtfsId = ?
    ''',
      [agencyId],
    );
    return RouteInfo.parseAll(maps);
  }

  Future<List<RouteInfo>> getFromStop(String stopId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT r.* FROM routes r
      INNER JOIN routes_stops sr ON r.gtfsId = sr.route_gtfsId
      WHERE sr.stop_gtfsId = ?
    ''',
      [stopId],
    );
    return RouteInfo.parseAll(maps);
  }
}
