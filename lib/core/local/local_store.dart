import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// O import do sqflite registra o databaseFactory NATIVO no mobile (iOS/Android);
// no desktop usamos o FFI. O lint acha redundante porque o ffi reexporta a API.
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Banco SQLite local — cache offline-first (P4). Singleton.
///
/// Mobile (iOS/Android) usa o sqflite nativo; desktop/macOS/testes usam FFI.
/// As tabelas de cache nascem aqui (`_onCreate`); novas features acrescentam
/// tabelas/migrações por aqui versionando [_version].
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static Database? _db;
  static const int _version = 3;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'dairy_cache.db');

    final isDesktop = !kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows);
    if (isDesktop) {
      sqfliteFfiInit();
      return databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
            version: _version, onCreate: _onCreate, onUpgrade: _onUpgrade),
      );
    }
    return openDatabase(path,
        version: _version, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  // Cada tabela espelha o JSON do backend → a leitura reusa o `fromJson` do
  // domínio. Chave = id remoto (upsert por REPLACE / replaceAll por snapshot).
  static const String _createProducts = '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL, price REAL,
      amount INTEGER, kg REAL, liters REAL, image_url TEXT, updated_at TEXT
    )''';

  static const String _createClients = '''
    CREATE TABLE clients (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL, phone TEXT, email TEXT,
      notes TEXT, sale_point_id INTEGER, updated_at TEXT
    )''';

  static const String _createOutbounds = '''
    CREATE TABLE outbounds (
      id INTEGER PRIMARY KEY, sale_point_id INTEGER, product_id INTEGER,
      name TEXT, status INTEGER, data TEXT, unidade TEXT, taken_quantity REAL,
      sold_quantity REAL, remaining_quantity REAL, total_value REAL,
      observacao TEXT, updated_at TEXT
    )''';

  // Fila de ESCRITA offline (vendas). `client_uuid` único garante idempotência
  // no flush; `payload` é o body JSON do POST a reenviar.
  static const String _createOutbox = '''
    CREATE TABLE outbox (
      id INTEGER PRIMARY KEY AUTOINCREMENT, client_uuid TEXT UNIQUE,
      sale_point_id INTEGER NOT NULL, payload TEXT NOT NULL,
      created_at TEXT, status TEXT, error TEXT
    )''';

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createProducts);
    await db.execute(_createClients);
    await db.execute(_createOutbounds);
    await db.execute(_createOutbox);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: tabelas de clientes e estoque (retiradas).
    if (oldVersion < 2) {
      await db.execute(_createClients);
      await db.execute(_createOutbounds);
    }
    // v2 → v3: fila de escrita offline (vendas).
    if (oldVersion < 3) {
      await db.execute(_createOutbox);
    }
  }
}
