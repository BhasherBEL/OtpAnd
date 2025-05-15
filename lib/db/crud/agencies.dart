import 'package:otpand/objects/agency.dart';
import 'package:sqflite/sqflite.dart';
import '../helper.dart';

class AgencyDao {
  final dbHelper = DatabaseHelper();

  Future<int> getOrInsert(Map<String, dynamic> agency) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'agencies',
      where: 'otpId = ?',
      whereArgs: [agency['otpId']],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return await db.insert(
      'agencies',
      agency,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insert(Map<String, dynamic> agency) async {
    final db = await dbHelper.database;
    return await db.insert(
      'agencies',
      agency,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Agency?> get(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'agencies',
      where: 'id = ?',
      whereArgs: [id],
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

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete('agencies', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Agency>> getFromRoute(int routeId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT a.* FROM agencies a
      INNER JOIN agencies_routes ar ON a.id = ar.agency_id
      WHERE ar.route_id = ?
    ''',
      [routeId],
    );
    return Agency.parseAll(maps);
  }
}
