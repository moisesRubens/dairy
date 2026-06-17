import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // 🔥 IMPORTANTE!

class DB {
  DB._();

  static final DB instance = DB._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 🔥 INICIALIZAÇÃO PARA WEB
    if (_isWeb()) {
      databaseFactory = databaseFactoryFfiWeb; // Usa a versão Web!
    } else {
      databaseFactory = databaseFactoryFfi; // Usa a versão Desktop/Teste
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dairy_database.db');
    
    print('📁 BANCO EM: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Verifica se está rodando na Web
  bool _isWeb() {
    return const bool.fromEnvironment('dart.library.html');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de produtos
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

    print('✅ Tabela "produtos" criada com sucesso!');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}