import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Serviço local SQLite para armazenamento relacional offline e consultas estruturadas.
/// Alinhado com o schema Prisma do backend Supabase/PostgreSQL (txeneza-web).
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabela de Categorias
    await db.execute('''
      CREATE TABLE categorias (
        id_categoria TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        icone TEXT
      )
    ''');

    // 2. Tabela de Ocorrências (Denúncias)
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

    // 3. Tabela de Pontos de Recolha
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

    // 4. Tabela de Utilizador (Perfil)
    await db.execute('''
      CREATE TABLE utilizador (
        id_utilizador TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        telefone TEXT,
        bairro TEXT NOT NULL,
        tipo TEXT DEFAULT 'morador',
        foto_perfil TEXT,
        estado TEXT DEFAULT 'activo',
        fcm_token TEXT,
        data_registo TEXT,
        data_atualizacao TEXT
      )
    ''');

    // 5. Tabela de Notificações
    await db.execute('''
      CREATE TABLE notificacao (
        id_notificacao TEXT PRIMARY KEY,
        id_utilizador TEXT NOT NULL,
        id_ocorrencia TEXT,
        tipo TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        lida INTEGER NOT NULL DEFAULT 0,
        data_hora TEXT NOT NULL
      )
    ''');

    // 6. Tabela de Verificações de Resolução
    await db.execute('''
      CREATE TABLE verificacao_resolucao (
        id_ocorrencia TEXT PRIMARY KEY,
        id_verificacao TEXT,
        foto_inicial_url TEXT,
        foto_resolucao_url TEXT,
        observacoes_equipa TEXT,
        data_resolucao TEXT,
        status_verificacao TEXT,
        observacoes_morador TEXT
      )
    ''');

    // 7. Tabela de Conversações com a Xeni (Chat IA)
    await db.execute('''
      CREATE TABLE conversacao_xeni (
        id_mensagem TEXT PRIMARY KEY,
        id_utilizador TEXT NOT NULL,
        mensagem_utilizador TEXT NOT NULL,
        resposta_xeni TEXT NOT NULL,
        modo TEXT DEFAULT 'gemini',
        data_hora TEXT NOT NULL
      )
    ''');

    // 8. Tabela de Fila de Sincronização Unificada (Sync Queue)
    await db.execute('''
      CREATE TABLE sync_queue (
        id_item TEXT PRIMARY KEY,
        tipo_operacao TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        file_path TEXT,
        data_criacao TEXT NOT NULL,
        tentativas INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pendente',
        ultimo_erro TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS utilizador (
          id_utilizador TEXT PRIMARY KEY,
          nome TEXT NOT NULL,
          email TEXT NOT NULL,
          telefone TEXT,
          bairro TEXT NOT NULL,
          tipo TEXT DEFAULT 'morador',
          foto_perfil TEXT,
          estado TEXT DEFAULT 'activo',
          fcm_token TEXT,
          data_registo TEXT,
          data_atualizacao TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS notificacao (
          id_notificacao TEXT PRIMARY KEY,
          id_utilizador TEXT NOT NULL,
          id_ocorrencia TEXT,
          tipo TEXT NOT NULL,
          mensagem TEXT NOT NULL,
          lida INTEGER NOT NULL DEFAULT 0,
          data_hora TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS verificacao_resolucao (
          id_ocorrencia TEXT PRIMARY KEY,
          id_verificacao TEXT,
          foto_inicial_url TEXT,
          foto_resolucao_url TEXT,
          observacoes_equipa TEXT,
          data_resolucao TEXT,
          status_verificacao TEXT,
          observacoes_morador TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS conversacao_xeni (
          id_mensagem TEXT PRIMARY KEY,
          id_utilizador TEXT NOT NULL,
          mensagem_utilizador TEXT NOT NULL,
          resposta_xeni TEXT NOT NULL,
          modo TEXT DEFAULT 'gemini',
          data_hora TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id_item TEXT PRIMARY KEY,
          tipo_operacao TEXT NOT NULL,
          payload_json TEXT NOT NULL,
          file_path TEXT,
          data_criacao TEXT NOT NULL,
          tentativas INTEGER DEFAULT 0,
          status TEXT DEFAULT 'pendente',
          ultimo_erro TEXT
        )
      ''');
    }
  }

  // ==========================================
  // --- 1. CATEGORIAS ---
  // ==========================================

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

  // ==========================================
  // --- 2. OCORRÊNCIAS ---
  // ==========================================

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
        orderBy: 'data_hora_registo DESC',
      );
    } catch (e) {
      debugPrint('Erro ao ler ocorrencias do SQLite: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOcorrenciaById(String idOcorrencia) async {
    try {
      final db = await database;
      final results = await db.query(
        'ocorrencias',
        where: 'id_ocorrencia = ?',
        whereArgs: [idOcorrencia],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      debugPrint('Erro ao ler ocorrencia por ID do SQLite: $e');
    }
    return null;
  }

  // ==========================================
  // --- 3. PONTOS DE RECOLHA ---
  // ==========================================

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

  // ==========================================
  // --- 4. PERFIL DO UTILIZADOR ---
  // ==========================================

  Future<void> savePerfil(Map<String, dynamic> perfil) async {
    try {
      final db = await database;
      await db.insert(
        'utilizador',
        {
          'id_utilizador': perfil['id_utilizador'],
          'nome': perfil['nome'],
          'email': perfil['email'],
          'telefone': perfil['telefone'],
          'bairro': perfil['bairro'],
          'tipo': perfil['tipo'] ?? 'morador',
          'foto_perfil': perfil['foto_perfil'],
          'estado': perfil['estado'] ?? 'activo',
          'fcm_token': perfil['fcm_token'],
          'data_registo': perfil['data_registo'],
          'data_atualizacao': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Erro ao salvar perfil no SQLite: $e');
    }
  }

  Future<Map<String, dynamic>?> getPerfil(String userId) async {
    try {
      final db = await database;
      final results = await db.query(
        'utilizador',
        where: 'id_utilizador = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      debugPrint('Erro ao ler perfil do SQLite: $e');
    }
    return null;
  }

  // ==========================================
  // --- 5. NOTIFICAÇÕES ---
  // ==========================================

  Future<void> saveNotificacoes(
      String userId, List<Map<String, dynamic>> notificacoes) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(
      'notificacao',
      where: 'id_utilizador = ?',
      whereArgs: [userId],
    );
    for (final notif in notificacoes) {
      batch.insert(
        'notificacao',
        {
          'id_notificacao': notif['id_notificacao'],
          'id_utilizador': userId,
          'id_ocorrencia': notif['id_ocorrencia'],
          'tipo': notif['tipo'],
          'mensagem': notif['mensagem'],
          'lida': (notif['lida'] == true || notif['lida'] == 1) ? 1 : 0,
          'data_hora': notif['data_hora'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getNotificacoes(String userId) async {
    try {
      final db = await database;
      return await db.query(
        'notificacao',
        where: 'id_utilizador = ?',
        whereArgs: [userId],
        orderBy: 'data_hora DESC',
      );
    } catch (e) {
      debugPrint('Erro ao ler notificações do SQLite: $e');
      return [];
    }
  }

  Future<void> updateNotificacaoLida(String idNotificacao, bool lida) async {
    try {
      final db = await database;
      await db.update(
        'notificacao',
        {'lida': lida ? 1 : 0},
        where: 'id_notificacao = ?',
        whereArgs: [idNotificacao],
      );
    } catch (e) {
      debugPrint('Erro ao atualizar estado de notificação no SQLite: $e');
    }
  }

  Future<void> marcarTodasNotificacoesLidas(String userId) async {
    try {
      final db = await database;
      await db.update(
        'notificacao',
        {'lida': 1},
        where: 'id_utilizador = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Erro ao marcar todas notificações lidas no SQLite: $e');
    }
  }

  Future<void> deleteNotificacao(String idNotificacao) async {
    try {
      final db = await database;
      await db.delete(
        'notificacao',
        where: 'id_notificacao = ?',
        whereArgs: [idNotificacao],
      );
    } catch (e) {
      debugPrint('Erro ao eliminar notificação no SQLite: $e');
    }
  }

  // ==========================================
  // --- 6. VERIFICAÇÕES DE RESOLUÇÃO ---
  // ==========================================

  Future<void> saveVerificacaoResolucao(Map<String, dynamic> verif) async {
    try {
      final db = await database;
      await db.insert(
        'verificacao_resolucao',
        {
          'id_ocorrencia': verif['id_ocorrencia'],
          'id_verificacao': verif['id_verificacao'],
          'foto_inicial_url': verif['foto_inicial_url'],
          'foto_resolucao_url': verif['foto_resolucao_url'],
          'observacoes_equipa': verif['observacoes_equipa'],
          'data_resolucao': verif['data_resolucao'],
          'status_verificacao': verif['status_verificacao'],
          'observacoes_morador': verif['observacoes_morador'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Erro ao salvar verificação de resolução no SQLite: $e');
    }
  }

  Future<Map<String, dynamic>?> getVerificacaoResolucao(
      String idOcorrencia) async {
    try {
      final db = await database;
      final results = await db.query(
        'verificacao_resolucao',
        where: 'id_ocorrencia = ?',
        whereArgs: [idOcorrencia],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      debugPrint('Erro ao ler verificação de resolução do SQLite: $e');
    }
    return null;
  }

  // ==========================================
  // --- 7. CHAT DA XENI (CONVERSAÇÃO IA) ---
  // ==========================================

  Future<void> saveMensagemChat({
    required String idMensagem,
    required String idUtilizador,
    required String mensagemUtilizador,
    required String respostaXeni,
    String modo = 'gemini',
    required String dataHora,
  }) async {
    try {
      final db = await database;
      await db.insert(
        'conversacao_xeni',
        {
          'id_mensagem': idMensagem,
          'id_utilizador': idUtilizador,
          'mensagem_utilizador': mensagemUtilizador,
          'resposta_xeni': respostaXeni,
          'modo': modo,
          'data_hora': dataHora,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Erro ao salvar mensagem de chat no SQLite: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMensagensChat(String userId) async {
    try {
      final db = await database;
      return await db.query(
        'conversacao_xeni',
        where: 'id_utilizador = ?',
        whereArgs: [userId],
        orderBy: 'data_hora ASC',
      );
    } catch (e) {
      debugPrint('Erro ao ler histórico de chat do SQLite: $e');
      return [];
    }
  }

  Future<void> clearMensagensChat(String userId) async {
    try {
      final db = await database;
      await db.delete(
        'conversacao_xeni',
        where: 'id_utilizador = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Erro ao limpar mensagens de chat no SQLite: $e');
    }
  }

  Future<void> clearAllMensagensChat() async {
    try {
      final db = await database;
      await db.delete('conversacao_xeni');
    } catch (e) {
      debugPrint('Erro ao limpar todas as mensagens de chat no SQLite: $e');
    }
  }

  // ==========================================
  // --- 8. FILA DE SINCRONIZAÇÃO (SYNC QUEUE) ---
  // ==========================================

  Future<void> enqueueSyncItem({
    required String idItem,
    required String tipoOperacao,
    required String payloadJson,
    String? filePath,
  }) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id_item': idItem,
        'tipo_operacao': tipoOperacao,
        'payload_json': payloadJson,
        'file_path': filePath,
        'data_criacao': DateTime.now().toIso8601String(),
        'tentativas': 0,
        'status': 'pendente',
        'ultimo_erro': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    try {
      final db = await database;
      return await db.query(
        'sync_queue',
        where: "status = 'pendente'",
        orderBy: 'data_criacao ASC',
      );
    } catch (e) {
      debugPrint('Erro ao ler fila de sincronização do SQLite: $e');
      return [];
    }
  }

  Future<int> getPendingSyncCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pendente'",
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> updateSyncItemStatus({
    required String idItem,
    required String status,
    int? tentativas,
    String? ultimoErro,
  }) async {
    try {
      final db = await database;
      final values = <String, dynamic>{'status': status};
      if (tentativas != null) values['tentativas'] = tentativas;
      if (ultimoErro != null) values['ultimo_erro'] = ultimoErro;

      await db.update(
        'sync_queue',
        values,
        where: 'id_item = ?',
        whereArgs: [idItem],
      );
    } catch (e) {
      debugPrint('Erro ao atualizar item na fila de sincronização: $e');
    }
  }

  Future<void> removeSyncItem(String idItem) async {
    try {
      final db = await database;
      await db.delete(
        'sync_queue',
        where: 'id_item = ?',
        whereArgs: [idItem],
      );
    } catch (e) {
      debugPrint('Erro ao remover item da fila de sincronização: $e');
    }
  }

  /// Limpeza completa de dados locais do utilizador ao fazer logout
  Future<void> clearUserData(String userId) async {
    try {
      final db = await database;
      final batch = db.batch();
      batch.delete('utilizador', where: 'id_utilizador = ?', whereArgs: [userId]);
      batch.delete('ocorrencias', where: 'id_utilizador = ?', whereArgs: [userId]);
      batch.delete('notificacao', where: 'id_utilizador = ?', whereArgs: [userId]);
      batch.delete('conversacao_xeni', where: 'id_utilizador = ?', whereArgs: [userId]);
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Erro ao limpar dados locais do utilizador: $e');
    }
  }
}
