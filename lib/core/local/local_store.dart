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
  static const int _version = 1;

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
        options: OpenDatabaseOptions(version: _version, onCreate: _onCreate),
      );
    }
    return openDatabase(path, version: _version, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cache do catálogo de produtos (chave = id remoto → upsert por REPLACE).
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL,
        amount INTEGER,
        kg REAL,
        liters REAL,
        image_url TEXT,
        updated_at TEXT
      )
    ''');
  }
}
