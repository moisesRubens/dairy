import 'package:dairy/domain/product.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider.internal();
  factory DatabaseProvider() => _instance;
  Database? _db;

  DatabaseProvider.internal();

  Future<Database> get db async {
    if(_db != null){
      return _db!;
    } else {
      _db = await initDb();
      return _db!;
    }
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "dairy.db");
    
    return await openDatabase (
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE products (
            ${Product.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${Product.productIdColumn} INTEGER UNIQUE,
            ${Product.nameColumn} TEXT NOT NULL,
            ${Product.priceColumn} REAL,
            ${Product.amountColumn} INTEGER,
            ${Product.kgColumn} REAL, 
            ${Product.litersColumn} REAL,
            updated_at TEXT
          );
        ''');
      },
    );
  }
}
