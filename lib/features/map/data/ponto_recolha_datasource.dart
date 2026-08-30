import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/sqlite_service.dart';
import '../../../core/network/cache_manager.dart';
import '../domain/ponto_recolha_model.dart';

/// Lê os pontos de recolha com suporte a SWR (Hive + SQLite + Supabase).
class PontoRecolhaDataSource {
  static const String _hiveKey = 'pontos_recolha_fast_list';

  SupabaseClient get _client => Supabase.instance.client;

  /// Devolve os pontos de recolha ativos via SWR:
  /// 1. Exibe instantaneamente os dados locais do Hive/SQLite.
  /// 2. Atualiza em segundo plano através do Supabase.
  Future<List<PontoRecolha>> fetchActivos() async {
    return await CacheManager.instance.executeSWR<PontoRecolha>(
      loadFromLocal: () async {
        // Tenta primeiro Hive
        final fastList = CacheManager.instance.getFast<List>(_hiveKey);
        if (fastList != null && fastList.isNotEmpty) {
          return fastList
              .map((item) =>
                  PontoRecolha.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }

        // De seguida tenta SQLite
        final sqliteRows = await SqliteService.instance.getPontosRecolha();
        if (sqliteRows.isNotEmpty) {
          return sqliteRows.map((row) => PontoRecolha.fromJson(row)).toList();
        }

        return [];
      },
      fetchFromRemote: () async {
        final rows = await _client
            .from('ponto_recolha')
            .select('id_ponto, nome, latitude, longitude, bairro, horario')
            .eq('estado', 'activo')
            .order('nome');

        return (rows as List)
            .map((row) => PontoRecolha.fromJson(row as Map<String, dynamic>))
            .toList();
      },
      saveToLocal: (freshList) async {
        final maps = freshList
            .map((p) => {
                  'id_ponto': p.id,
                  'nome': p.nome,
                  'latitude': p.position.latitude,
                  'longitude': p.position.longitude,
                  'bairro': p.bairro,
                  'horario': p.horario,
                })
            .toList();

        await SqliteService.instance.savePontosRecolha(maps);
        await CacheManager.instance.putFast(_hiveKey, maps);
      },
    );
  }
}
