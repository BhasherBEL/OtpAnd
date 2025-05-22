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
    final documentsDirectory = await getDownloadsDirectory();
    final path = join(documentsDirectory!.path, 'app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        avoidDirectWalking INTEGER NOT NULL,
        walkPreference REAL NOT NULL,
        walkSafetyPreference REAL NOT NULL,
        walkSpeed REAL NOT NULL,
        transit INTEGER NOT NULL,
        transitPreference REAL NOT NULL,
        transitWaitReluctance REAL NOT NULL,
        transitTransferWorth REAL NOT NULL,
        transitMinimalTransferTime INTEGER NOT NULL,
        wheelchairAccessible INTEGER NOT NULL,
        bike INTEGER NOT NULL,
        bikePreference REAL NOT NULL,
        bikeFlatnessPreference REAL NOT NULL,
        bikeSafetyPreference REAL NOT NULL,
        bikeSpeed REAL NOT NULL,
        bikeFriendly INTEGER NOT NULL,
        bikeParkRide INTEGER NOT NULL,
        car INTEGER NOT NULL,
        carPreference REAL NOT NULL,
        carParkRide INTEGER NOT NULL,
        carKissRide INTEGER NOT NULL,
        carPickup INTEGER NOT NULL
      )
    ''');

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
        mode TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE stops (
        gtfsId TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        platformCode TEXT,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
				mode TEXT 
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

    await db.execute('''
      CREATE TABLE directions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_gtfsId TEXT NOT NULL,
        headsign TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE direction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        direction_id INTEGER NOT NULL,
        stop_gtfsId TEXT NOT NULL,
        "order" INTEGER NOT NULL,
        FOREIGN KEY (direction_id) REFERENCES directions(id)
      )
    ''');
  }
}
