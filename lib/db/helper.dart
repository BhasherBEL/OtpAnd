import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE agencies (
        gtfsId TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        url TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE routes (
        gtfsId TEXT PRIMARY KEY,
        longName TEXT NOT NULL,
        shortName TEXT NOT NULL,
        color INTEGER,
        textColor INTEGER,
        mode TEXT NOT NULL,
      )
    ''');
    await db.execute('''
      CREATE TABLE stops (
        gtfsId TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        platformCode TEXT,
        lat REAL NOT NULL,
        lon REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routes_stops (
        stop_gtfsId TEXT NOT NULL,
        route_gtfsId TEXT NOT NULL,
        PRIMARY KEY (stop_gtfsId, route_gtfsId),
        FOREIGN KEY (stop_gtfsId) REFERENCES stops(gtfsId),
        FOREIGN KEY (route_gtfsId) REFERENCES routes(gtfsId)
      )
    ''');

    await db.execute('''
      CREATE TABLE agencies_routes (
        agency_gtfsId TEXT NOT NULL,
        route_gtfsId TEXT NOT NULL,
        PRIMARY KEY (agency_gtfsId, route_gtfsId),
        FOREIGN KEY (agency_gtfsId) REFERENCES agencies(gtfsId),
        FOREIGN KEY (route_gtfsId) REFERENCES routes(gtfsId)
      )
    ''');
  }
}
