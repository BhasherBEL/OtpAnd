import 'package:otpand/objects/favourite.dart';
import 'package:otpand/objs.dart';
import 'package:sqflite/sqflite.dart';
import '../helper.dart';

class FavouriteDao {
  final dbHelper = DatabaseHelper();

  Future<void> insert(Map<String, dynamic> favourite) async {
    final db = await dbHelper.database;
    await db.insert(
      'favourites',
      favourite,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Favourite> insertFromLocation(Location location) async {
    final db = await dbHelper.database;
    final data = {
      'name': location.name,
      'lat': location.lat,
      'lon': location.lon,
      'stopGtfsId': location.stop?.gtfsId,
    };
    final id = await db.insert(
      'favourites',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return Favourite(
      id: id,
      name: location.name,
      lat: location.lat,
      lon: location.lon,
      stop: location.stop,
    );
  }

  Future<List<Favourite>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('favourites');
    return Future.wait(maps.map((e) => Favourite.parse(e)));
  }

  Future<int> delete(String id) async {
    final db = await dbHelper.database;
    return await db.delete('favourites', where: 'id = ?', whereArgs: [id]);
  }
}
