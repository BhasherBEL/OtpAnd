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
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        otpId TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        url TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        otpId TEXT NOT NULL UNIQUE,
        agency_id INTEGER,
        longName TEXT NOT NULL,
        shortName TEXT NOT NULL,
        color INTEGER,
        textColor INTEGER,
        mode TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE stops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        otpId TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        platformCode TEXT,
        lat REAL NOT NULL,
        lon REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routes_stops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stop_id INTEGER NOT NULL,
        route_id INTEGER NOT NULL,
        FOREIGN KEY (stop_id) REFERENCES stops(id),
        FOREIGN KEY (route_id) REFERENCES routes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE agencies_routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agency_id INTEGER NOT NULL,
        route_id INTEGER NOT NULL,
        FOREIGN KEY (agency_id) REFERENCES agencies(id),
        FOREIGN KEY (route_id) REFERENCES routes(id)
      )
    ''');
  }
}
