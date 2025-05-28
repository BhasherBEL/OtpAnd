import 'package:sqflite/sqflite.dart';
import 'package:otpand/objects/direction.dart';
import 'package:otpand/db/helper.dart';

class DirectionDao {
  final dbHelper = DatabaseHelper();

  Future<List<int?>> batchInsert(List<Map<String, dynamic>> directions) async {
    if (directions.isEmpty) return [];
    final db = await dbHelper.database;
    final batch = db.batch();

    for (final direction in directions) {
      final directionMap = {
        'route_gtfsId': direction['route_gtfsId'],
        'headsign': direction['headsign'],
      };
      batch.insert(
        'directions',
        directionMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return (await batch.commit(noResult: false)).cast<int>();
  }

  Future<int> insert(Map<String, dynamic> direction) async {
    final db = await dbHelper.database;
    final directionMap = {
      'route_gtfsId': direction['route_gtfsId'],
      'headsign': direction['headsign'],
    };
    final directionId = await db.insert(
      'directions',
      directionMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return directionId;
  }

  Future<Direction?> get(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'directions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Direction.parse(maps.first);
  }

  Future<List<Direction>> getAll() async {
    final db = await dbHelper.database;
    final directions = await db.query('directions');
    if (directions.isEmpty) return [];
    return Direction.parseAll(directions);
  }

  Future<List<Direction>> getFromRoute(String routeGtfsId) async {
    final db = await dbHelper.database;
    final directions = await db.query(
      'directions',
      where: 'route_gtfsId = ?',
      whereArgs: [routeGtfsId],
    );
    if (directions.isEmpty) return [];

    return Direction.parseAll(directions);
  }
}
