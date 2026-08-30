import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../database/sqlite_service.dart';

/// Gestor unificado de Cache e Sincronização SWR (Stale-While-Revalidate).
/// Combina Hive (NoSQL ultrarrápido L1 em memória/disco) e SQLite (Relacional L2 local).
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

  // --- HIVE KEY-VALUE FAST ACCESS (L1) ---

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

  /// Remove uma chave específica da cache rápida
  Future<void> removeFast(String key) async {
    try {
      if (_fastBox != null && _fastBox!.containsKey(key)) {
        await _fastBox!.delete(key);
      }
    } catch (e) {
      debugPrint('Erro ao remover do Hive ($key): $e');
    }
  }

  /// Limpa todas as caches rápidas do utilizador (ex: ao fazer logout)
  Future<void> clearUserCache(String userId) async {
    try {
      await removeFast('profile_fast_$userId');
      await removeFast('stats_fast_$userId');
      await removeFast('ocorrencias_fast_$userId');
      await removeFast('unread_notif_count_$userId');
      await SqliteService.instance.clearUserData(userId);
    } catch (e) {
      debugPrint('Erro ao limpar cache do utilizador ($userId): $e');
    }
  }

  // --- STALE-WHILE-REVALIDATE PATTERN WRAPPER ---

  /// Executa o padrão SWR para listas:
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
      if (freshData.isNotEmpty || localData.isNotEmpty) {
        await saveToLocal(freshData);
        return freshData;
      }
    } catch (e) {
      debugPrint('SWR remote fetch failed, usando cache local ($e)');
    }

    return localData;
  }

  /// Executa o padrão SWR para um item único (ex: Perfil, Verificação de Resolução)
  Future<T?> executeSingleSWR<T>({
    required Future<T?> Function() loadFromLocal,
    required Future<T> Function() fetchFromRemote,
    required Future<void> Function(T freshData) saveToLocal,
  }) async {
    T? localData;
    try {
      localData = await loadFromLocal();
    } catch (e) {
      debugPrint('Single SWR local load fallback: $e');
    }

    try {
      final freshData = await fetchFromRemote();
      await saveToLocal(freshData);
      return freshData;
    } catch (e) {
      debugPrint('Single SWR remote fetch failed, usando cache local ($e)');
    }

    return localData;
  }
}
