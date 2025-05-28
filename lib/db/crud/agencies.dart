import 'package:otpand/objects/agency.dart';
import 'package:sqflite/sqflite.dart';
import 'package:otpand/db/helper.dart';

class AgencyDao {
  final dbHelper = DatabaseHelper();

  Future<void> batchInsert(List<Map<String, dynamic>> agencies) async {
    if (agencies.isEmpty) return;
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final agency in agencies) {
      batch.insert(
        'agencies',
        agency,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> insert(Map<String, dynamic> agency) async {
    final db = await dbHelper.database;
    return await db.insert(
      'agencies',
      agency,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Agency?> get(String gtfsId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'agencies',
      where: 'gtfsId = ?',
      whereArgs: [gtfsId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Agency.parse(maps.first);
    }
    return null;
  }

  Future<List<Agency>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('agencies');
    return Agency.parseAll(maps);
  }

  Future<int> delete(String gtfsId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'agencies',
      where: 'gtfsId = ?',
      whereArgs: [gtfsId],
    );
  }

  Future<List<Agency>> getFromRoute(String routeId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT a.* FROM agencies a
      INNER JOIN agencies_routes ar ON a.gtfsId = ar.agency_gtfsId
      WHERE ar.route_gtfsId = ?
    ''',
      [routeId],
    );
    return Agency.parseAll(maps);
  }
}
