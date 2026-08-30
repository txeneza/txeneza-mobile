import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Serviço local SQLite para armazenamento relacional offline e consultas rápidas.
class SqliteService {
  static final SqliteService instance = SqliteService._internal();
  static Database? _database;

  SqliteService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'txeneza_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de Categorias
    await db.execute('''
      CREATE TABLE categorias (
        id_categoria TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        icone TEXT
      )
    ''');

    // Tabela de Ocorrências (Denúncias)
    await db.execute('''
      CREATE TABLE ocorrencias (
        id_ocorrencia TEXT PRIMARY KEY,
        id_utilizador TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        descricao TEXT,
        estado TEXT,
        gravidade TEXT,
        nome_categoria TEXT,
        photo_url TEXT,
        data_hora_registo TEXT
      )
    ''');

    // Tabela de Pontos de Recolha
    await db.execute('''
      CREATE TABLE pontos_recolha (
        id_ponto TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        bairro TEXT,
        horario TEXT
      )
    ''');
  }

  // --- Operações de Categorias ---

  Future<void> saveCategorias(List<Map<String, dynamic>> categorias) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('categorias');
    for (final cat in categorias) {
      batch.insert(
        'categorias',
        {
          'id_categoria': cat['id_categoria'],
          'nome': cat['nome'],
          'icone': cat['icone'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCategorias() async {
    try {
      final db = await database;
      return await db.query('categorias', orderBy: 'nome ASC');
    } catch (e) {
      debugPrint('Erro ao ler categorias do SQLite: $e');
      return [];
    }
  }

  // --- Operações de Ocorrências ---

  Future<void> saveOcorrencias(
      String userId, List<Map<String, dynamic>> ocorrencias) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(
      'ocorrencias',
      where: 'id_utilizador = ?',
      whereArgs: [userId],
    );
    for (final item in ocorrencias) {
      batch.insert(
        'ocorrencias',
        {
          'id_ocorrencia': item['id_ocorrencia'],
          'id_utilizador': userId,
          'latitude': item['latitude'],
          'longitude': item['longitude'],
          'descricao': item['descricao'],
          'estado': item['estado'],
          'gravidade': item['gravidade'],
          'nome_categoria': item['nome_categoria'],
          'photo_url': item['photo_url'],
          'data_hora_registo': item['data_hora_registo'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getOcorrencias(String userId) async {
    try {
      final db = await database;
      return await db.query(
        'ocorrencias',
        where: 'id_utilizador = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Erro ao ler ocorrencias do SQLite: $e');
      return [];
    }
  }

  // --- Operações de Pontos de Recolha ---

  Future<void> savePontosRecolha(List<Map<String, dynamic>> pontos) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('pontos_recolha');
    for (final ponto in pontos) {
      batch.insert(
        'pontos_recolha',
        {
          'id_ponto': ponto['id_ponto'],
          'nome': ponto['nome'],
          'latitude': ponto['latitude'],
          'longitude': ponto['longitude'],
          'bairro': ponto['bairro'],
          'horario': ponto['horario'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getPontosRecolha() async {
    try {
      final db = await database;
      return await db.query('pontos_recolha', orderBy: 'nome ASC');
    } catch (e) {
      debugPrint('Erro ao ler pontos de recolha do SQLite: $e');
      return [];
    }
  }
}
