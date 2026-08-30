import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/sqlite_service.dart';
import '../../../core/network/cache_manager.dart';
import '../domain/categoria.dart';

/// Lê as categorias de resíduo com suporte a SWR (Hive + SQLite + Supabase).
class CategoriaDataSource {
  static const String _hiveKey = 'categorias_fast_list';

  SupabaseClient get _client => Supabase.instance.client;

  List<Categoria>? _memoryCache;

  /// Devolve as categorias usando a estratégia SWR:
  /// 1. Retorna instantaneamente a cache do Hive/SQLite.
  /// 2. Atualiza a partir do Supabase em background se disponível.
  Future<List<Categoria>> fetchAll({bool forceRefresh = false}) async {
    if (_memoryCache != null && !forceRefresh) return _memoryCache!;

    final result = await CacheManager.instance.executeSWR<Categoria>(
      loadFromLocal: () async {
        // Tenta primeiro Hive (fast key-value)
        final fastList = CacheManager.instance.getFast<List>(_hiveKey);
        if (fastList != null && fastList.isNotEmpty) {
          return fastList
              .map((item) => Categoria.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }

        // Caso não esteja na Hive, lê do SQLite
        final sqliteRows = await SqliteService.instance.getCategorias();
        if (sqliteRows.isNotEmpty) {
          return sqliteRows.map((r) => Categoria.fromJson(r)).toList();
        }

        return Categoria.defaultOfflineCategorias;
      },
      fetchFromRemote: () async {
        final rows = await _client
            .from('categoria_residuo')
            .select('id_categoria, nome, icone')
            .order('nome');

        return (rows as List)
            .map((r) => Categoria.fromJson(r as Map<String, dynamic>))
            .toList();
      },
      saveToLocal: (freshList) async {
        _memoryCache = freshList;
        final maps = freshList
            .map((c) => {
                  'id_categoria': c.id,
                  'nome': c.nome,
                  'icone': c.icone,
                })
            .toList();

        // Salva tanto no SQLite (relacional) como no Hive (fast lookup)
        await SqliteService.instance.saveCategorias(maps);
        await CacheManager.instance.putFast(_hiveKey, maps);
      },
    );

    _memoryCache = result.isNotEmpty ? result : Categoria.defaultOfflineCategorias;
    return _memoryCache!;
  }
}
