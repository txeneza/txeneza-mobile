import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../database/sqlite_service.dart';

/// Gestor unificado de Cache e Sincronização SWR (Stale-While-Revalidate).
/// Combina Hive (NoSQL ultrarrápido em memória/disco) e SQLite (Relacional local).
class CacheManager {
  static final CacheManager instance = CacheManager._internal();
  static const String appBoxName = 'txeneza_fast_cache';

  Box? _fastBox;

  CacheManager._internal();

  /// Inicializa o Hive e o SQLite na inicialização do aplicativo.
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _fastBox = await Hive.openBox(appBoxName);
      // Inicializa o banco de dados SQLite local
      await SqliteService.instance.database;
      debugPrint('CacheManager e SQLite inicializados com sucesso.');
    } catch (e) {
      debugPrint('Erro ao inicializar o CacheManager: $e');
    }
  }

  // --- HIVE KEY-VALUE FAST ACCESS ---

  /// Escreve um valor rápido na cache Hive
  Future<void> putFast(String key, dynamic value) async {
    try {
      if (_fastBox != null) {
        await _fastBox!.put(key, value);
      }
    } catch (e) {
      debugPrint('Erro ao guardar no Hive ($key): $e');
    }
  }

  /// Lê um valor rápido da cache Hive
  T? getFast<T>(String key) {
    try {
      if (_fastBox != null && _fastBox!.containsKey(key)) {
        return _fastBox!.get(key) as T?;
      }
    } catch (e) {
      debugPrint('Erro ao ler do Hive ($key): $e');
    }
    return null;
  }

  // --- STALE-WHILE-REVALIDATE PATTERN WRAPPER ---

  /// Executa o padrão SWR:
  /// 1. Tenta obter o resultado da cache local (Hive/SQLite) instantaneamente.
  /// 2. Executa a requisição remota (Supabase) em segundo plano.
  /// 3. Salva a resposta atualizada na cache local.
  /// 4. Notifica/Devolve o novo dado atualizado se houver alterações.
  Future<List<T>> executeSWR<T>({
    required Future<List<T>> Function() loadFromLocal,
    required Future<List<T>> Function() fetchFromRemote,
    required Future<void> Function(List<T> freshData) saveToLocal,
  }) async {
    // 1. Leitura Local Instantânea (0ms)
    List<T> localData = [];
    try {
      localData = await loadFromLocal();
    } catch (e) {
      debugPrint('SWR local load fallback: $e');
    }

    // 2. Busca Remota e Atualização Silenciosa em Background
    try {
      final freshData = await fetchFromRemote();
      if (freshData.isNotEmpty) {
        await saveToLocal(freshData);
        return freshData;
      }
    } catch (e) {
      debugPrint('SWR remote fetch failed, usando cache local ($e)');
    }

    return localData;
  }
}
