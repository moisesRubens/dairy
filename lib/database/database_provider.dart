import 'package:dairy/domain/product.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:dairy/domain/order2.dart';

class DatabaseProvider {
  Database? _db;
  
  factory DatabaseProvider() => _instance;
  static final DatabaseProvider _instance = DatabaseProvider.internal();
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
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, "dairy_database.db");
      
      return await openDatabase (
        path,
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch(e) {
      throw Exception('Erro ao inicializar banco de dados: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE products (
          ${Product.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${Product.productIdColumn} INTEGER UNIQUE,
          ${Product.nameColumn} TEXT NOT NULL,
          ${Product.priceColumn} REAL,
          ${Product.amountColumn} INTEGER,
          ${Product.kgColumn} REAL, 
          ${Product.litersColumn} REAL,
          ${Product.dateColumn} TEXT,
          updated_at TEXT
        );
      ''');
      await db.execute('''
        CREATE TABLE orders (
          ${Order.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${Order.orderIdColumn} INTEGER UNIQUE,
          ${Order.statusColumn} INT NOT NULL,
          ${Order.totalValueColumn} REAL,
          ${Order.dateTimeColumn} TEXT NOT NULL,
          ${Order.descriptionColumn} TEXT, 
          updated_at TEXT
        );
      ''');    
      await db.execute('''
        CREATE TABLE order_product (
          ${Order.orderIdColumn} INT,
          ${Product.productIdColumn} INT,
          unit TEXT NOT NULL,
          ${Product.priceColumn} REAL NOT NULL,
          CONSTRAINT pk_order_product PRIMARY KEY (${Order.orderIdColumn}, ${Product.productIdColumn}),
          FOREIGN KEY ${Order.orderIdColumn} REFERENCES orders(${Order.idColumn})
            ON DELETE CASCADE,
          FOREIGN KEY ${Product.productIdColumn} REFERENCES products(${Product.idColumn})
            ON DELETE SET NULL
        );
      ''');
    } catch(e) {
      throw Exception('Erro ao criar banco de dados: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try{
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE products ADD COLUMN ${Product.dateColumn} TEXT');
      }
      if (oldVersion < 3) {
        await db.execute('''
          CREATE TABLE orders (
            ${Order.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${Order.orderIdColumn} INTEGER UNIQUE,
            ${Order.statusColumn} INT NOT NULL,
            ${Order.totalValueColumn} REAL,
            ${Order.dateTimeColumn} TEXT NOT NULL,
            ${Order.descriptionColumn} TEXT, 
            updated_at TEXT
          );
        ''');
      } 
      if(oldVersion < 4) {
        await db.execute('''
          CREATE TABLE order_product (
          ${Order.orderIdColumn} INT,
          ${Product.productIdColumn} INT,
          unit TEXT NOT NULL,
          ${Product.priceColumn} REAL NOT NULL,
          CONSTRAINT pk_order_product PRIMARY KEY (${Order.orderIdColumn}, ${Product.productIdColumn}),
          FOREIGN KEY ${Order.orderIdColumn} REFERENCES orders(${Order.idColumn})
            ON DELETE CASCADE,
          FOREIGN KEY ${Product.productIdColumn} REFERENCES products(${Product.idColumn})
            ON DELETE SET NULL
          );
        ''');
      }
    } catch(e) {
      throw Exception('Erro ao atualizar banco de dados: $e');
    }
  }
}
