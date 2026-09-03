import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DB {
  DB._();

  static final DB instance = DB._();
  static Database? _database;
  static bool _initialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async 
  {
    if (!_initialized) 
    {
      await _configureDatabaseFactory();
      _initialized = true;
    }
    final path = await _getDatabasePath();
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _configureDatabaseFactory() async 
  {
    try 
    {
      if (_isWeb()) 
      {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isAndroid || Platform.isIOS) 
      {
      } 
      else 
      {
        // DESKTOP - Usa o FFI
        databaseFactory = databaseFactoryFfi;
      }
    } 
    catch (e) 
    {
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<String> _getDatabasePath() async 
  {
    try {
      String path;
      if (_isWeb()) 
      {
        path = 'dairy_database.db';
      } 
      else if (Platform.isAndroid || Platform.isIOS) 
      {
        final directory = await getApplicationDocumentsDirectory();
        path = join(directory.path, 'dairy_database.db');
      } 
      else if (Platform.isWindows) 
      {
        final directory = await getApplicationSupportDirectory();
        path = join(directory.path, 'dairy_database.db');
      } 
      else if (Platform.isLinux || Platform.isMacOS) 
      {
        final directory = await getApplicationSupportDirectory();
        path = join(directory.path, 'dairy_database.db');
      } 
      else 
      {
        final directory = await getDatabasesPath();
        path = join(directory, 'dairy_database.db');
      }
      
      if (!_isWeb()) 
      {
        final dir = Directory(dirname(path));
        if (!await dir.exists())
        {
          await dir.create(recursive: true);
        }
      }
      return path;
    } catch (e) {
      print('❌ Erro ao obter caminho do banco: $e');
      // Fallback para o caminho mais simples
      return 'dairy_database.db';
    }
  }

  // Verifica se está rodando na Web
  bool _isWeb() {
    return const bool.fromEnvironment('dart.library.html');
  }

  // Nome da plataforma para debug
  Future<String> _getPlatformName() async {
    if (_isWeb()) return '🌐 Web';
    if (Platform.isAndroid) return '📱 Android';
    if (Platform.isIOS) return '📱 iOS';
    if (Platform.isWindows) return '🪟 Windows';
    if (Platform.isLinux) return '🐧 Linux';
    if (Platform.isMacOS) return '🍎 macOS';
    return '❓ Desconhecida';
  }

  // ============================================================
  // 🔥 CRIAÇÃO DO BANCO DE DADOS (VERSÃO 3)
  // ============================================================
  Future<void> _onCreate(Database db, int version) async
  {
    try 
    {
      await db.execute('''
        CREATE TABLE produtos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          produtoId INTEGER UNIQUE,
          name TEXT NOT NULL,
          price REAL,
          amount INTEGER,
          kg REAL,
          liters REAL,
          updatedAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER UNIQUE,
          sale_point_id INTEGER,
          description TEXT,
          status INTEGER,
          total_value REAL,
          order_date TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER,
          product_id INTEGER,
          product_name TEXT,
          item_price REAL,
          amount INTEGER,
          kg REAL,
          liters REAL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX idx_produtos_name ON produtos(name)');
      await db.execute('CREATE INDEX idx_produtos_produtoId ON produtos(produtoId)');
      await db.execute('CREATE INDEX idx_orders_orderId ON orders(orderId)');
      await db.execute('CREATE INDEX idx_orders_order_date ON orders(order_date)');
      await db.execute('CREATE INDEX idx_order_items_order_id ON order_items(order_id)');
    } 
    catch (e) 
    {
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async 
  {
    try 
    {
      if (oldVersion < 2) 
      {
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            orderId INTEGER UNIQUE,
            sale_point_id INTEGER,
            description TEXT,
            status INTEGER,
            total_value REAL,
            order_date TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER,
            product_id INTEGER,
            product_name TEXT,
            item_price REAL,
            amount INTEGER,
            kg REAL,
            liters REAL,
            FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('CREATE INDEX idx_orders_orderId ON orders(orderId)');
        await db.execute('CREATE INDEX idx_orders_order_date ON orders(order_date)');
        await db.execute('CREATE INDEX idx_order_items_order_id ON order_items(order_id)');
      }
      
      if (oldVersion < 3) 
      {
        try 
        {
          final columns = await db.rawQuery('PRAGMA table_info(order_items)');
          final hasProductName = columns.any((col) => col['name'] == 'product_name');
          final hasItemPrice = columns.any((col) => col['name'] == 'item_price');
          
          if (!hasProductName) 
          {
            await db.execute('ALTER TABLE order_items ADD COLUMN product_name TEXT');
          }
          if (!hasItemPrice) 
          {
            await db.execute('ALTER TABLE order_items ADD COLUMN item_price REAL');
          }
        }
        catch (e) 
        {
          print('⚠️ Erro ao adicionar colunas (podem já existir): $e');
        }
      }
    } 
    catch (e)
    {
      rethrow;
    }
  }

  // ============================================================
  // 🔥 FECHA A CONEXÃO COM O BANCO
  // ============================================================
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initialized = false;
      print('🔒 Banco de dados fechado');
    }
  }

  // ============================================================
  // 🔥 MÉTODO PARA DELETAR O BANCO (útil para reset)
  // ============================================================
  Future<void> deleteDatabase() async {
    try {
      await close();
      final path = await _getDatabasePath();
      if (!_isWeb()) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Banco de dados deletado: $path');
        }
      }
    } catch (e) {
      print('❌ Erro ao deletar banco: $e');
    }
  }
}