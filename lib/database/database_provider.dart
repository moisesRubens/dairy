import 'package:dairy/domain/product.dart';
import 'package:dairy/domain/sale_point.dart';
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
    if (_db != null) {
      return _db!;
    } else {
      _db = await initDb();
      return _db!;
    }
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, "dairy_database.db");

      return await openDatabase(
        path,
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE products (
          ${Product.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${Product.productIdColumn} INT UNIQUE,
          ${Product.nameColumn} TEXT NOT NULL,
          ${Product.priceColumn} REAL NOT NULL,
          ${Product.unitColumn} TEXT NOT NULL CHECK(${Product.unitColumn} IN ('kg', 'amount', 'liters')),
          ${Product.quantityColumn} REAL NOT NULL,
          ${Product.dateColumn} TEXT,
          updated_at TEXT
        );
      ''');
      await db.execute('''
        CREATE TABLE orders (
          ${Order.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${Order.orderIdColumn} INT UNIQUE,
          ${Order.statusColumn} TEXT NOT NULL CHECK(${Order.statusColumn} IN ('paid', 'pending', 'discount')),
          ${Order.discountValueColumn} REAL,
          ${Order.totalValueColumn} REAL,
          ${Order.dateTimeColumn} TEXT NOT NULL,
          ${Order.descriptionColumn} TEXT, 
          updated_at TEXT 
        );
      ''');
      await db.execute('''
        CREATE TABLE order_product (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          order_id INT,
          product_id INT,
          unit TEXT NOT NULL CHECK (unit IN ('kg', 'liters', 'amount')),
          discount_value REAL,
          name_product TEXT NOT NULL, 
          ${Product.priceColumn} REAL NOT NULL,
          CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders(${Order.idColumn}) ON DELETE SET NULL,
          CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(${Product.idColumn}) ON DELETE SET NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE sales_points (
          ${SalePoint.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${SalePoint.salePointIdColumn} INT UNIQUE,
          ${SalePoint.nameColumn} TEXT NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE sale_point_order (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_point_id INT NOT NULL,
          order_id INT NOT NULL,
          date TEXT,
          CONSTRAINT fk_sale_point FOREIGN KEY (sale_point_id) REFERENCES sales_points(${SalePoint.idColumn}) ON DELETE  CASCADE,
          CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders(${Order.idColumn}) ON DELETE CASCADE
        );
      ''');
    } catch (e) {
      throw Exception('Erro ao criar banco de dados: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    
  }
}
