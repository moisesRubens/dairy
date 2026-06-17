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

  Future<Database> _initDatabase() async {
    // 🔥 INICIALIZAÇÃO DA FÁBRICA (APENAS UMA VEZ)
    if (!_initialized) {
      await _configureDatabaseFactory();
      _initialized = true;
    }

    // 🔥 CAMINHO DINÂMICO POR PLATAFORMA
    final path = await _getDatabasePath();
    
    print('📁 BANCO EM: $path');
    print('🖥️ PLATAFORMA: ${await _getPlatformName()}');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 🔥 CONFIGURA A FÁBRICA CORRETA PARA CADA PLATAFORMA
  Future<void> _configureDatabaseFactory() async {
    try {
      if (_isWeb()) {
        // 🌐 WEB - Usa o FFI para Web
        print('🌐 Configurando database factory para WEB');
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 📱 MOBILE - Usa o sqflite nativo (já é o padrão)
        print('📱 Usando database factory nativa para MOBILE');
        // Não precisa mudar, sqflite já usa a nativa por padrão
      } else {
        // 💻 DESKTOP - Usa o FFI
        print('💻 Configurando database factory para DESKTOP');
        databaseFactory = databaseFactoryFfi;
      }
    } catch (e) {
      print('❌ Erro ao configurar database factory: $e');
      // Fallback para o padrão
      databaseFactory = databaseFactoryFfi;
    }
  }

  // 🔥 OBTÉM O CAMINHO CORRETO PARA CADA PLATAFORMA
  Future<String> _getDatabasePath() async {
    try {
      String path;
      
      if (_isWeb()) {
        // 🌐 WEB - Usa apenas o nome do arquivo (salvo no IndexedDB)
        path = 'dairy_database.db';
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 📱 MOBILE - Diretório de documentos do app
        final directory = await getApplicationDocumentsDirectory();
        path = join(directory.path, 'dairy_database.db');
      } else if (Platform.isWindows) {
        // 🪟 WINDOWS - AppData/Local/SeuApp
        final directory = await getApplicationSupportDirectory();
        path = join(directory.path, 'dairy_database.db');
      } else if (Platform.isLinux || Platform.isMacOS) {
        // 🐧 LINUX / 🍎 MAC - Diretório do usuário
        final directory = await getApplicationSupportDirectory();
        path = join(directory.path, 'dairy_database.db');
      } else {
        // FALLBACK - Usa o diretório padrão do sqflite
        final directory = await getDatabasesPath();
        path = join(directory, 'dairy_database.db');
      }
      
      // Cria o diretório se não existir (exceto na web)
      if (!_isWeb()) {
        final dir = Directory(dirname(path));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          print('📁 Diretório criado: ${dir.path}');
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

  // 🔥 CRIAÇÃO DO BANCO DE DADOS
  Future<void> _onCreate(Database db, int version) async {
    print('🔄 Criando banco de dados versão $version...');
    
    try {
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

      // Índices para melhor performance
      await db.execute('CREATE INDEX idx_produtos_name ON produtos(name)');
      await db.execute('CREATE INDEX idx_produtos_produtoId ON produtos(produtoId)');

      print('✅ Tabela "produtos" criada com sucesso!');
      
      // Dados iniciais (opcional)
      // await _insertInitialData(db);
      
    } catch (e) {
      print('❌ Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  // 🔥 UPGRADE DO BANCO DE DADOS
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Atualizando banco de dados de $oldVersion para $newVersion...');
    
    try {
      // Exemplo de upgrade
      if (oldVersion < 2) {
        // Adicionar nova coluna
        // await db.execute('ALTER TABLE produtos ADD COLUMN category TEXT');
      }
      
      print('✅ Banco atualizado com sucesso!');
    } catch (e) {
      print('❌ Erro ao atualizar banco: $e');
      rethrow;
    }
  }

  // Método para popular com dados iniciais (opcional)
  Future<void> _insertInitialData(Database db) async {
    // Adiciona alguns produtos de exemplo
    // await db.insert('produtos', {
    //   'name': 'Produto Exemplo',
    //   'price': 10.0,
    //   'amount': 100,
    // });
  }

  // 🔥 FECHA A CONEXÃO COM O BANCO
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initialized = false;
      print('🔒 Banco de dados fechado');
    }
  }

  // 🔥 MÉTODO PARA DELETAR O BANCO (útil para reset)
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