import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/categoria.dart';

/// Lê as categorias de resíduo (leitura pública, ver migração 0005).
///
/// Guarda a última lista em `shared_preferences` para que o formulário de
/// denúncia funcione offline, desde que tenha carregado uma vez com rede.
class CategoriaDataSource {
  static const String _prefsKey = 'categorias_cache';

  SupabaseClient get _client => Supabase.instance.client;

  List<Categoria>? _memoryCache;

  /// Devolve as categorias. Tenta a rede; se falhar, usa a cache local.
  Future<List<Categoria>> fetchAll({bool forceRefresh = false}) async {
    if (_memoryCache != null && !forceRefresh) return _memoryCache!;

    try {
      final rows = await _client
          .from('categoria_residuo')
          .select('id_categoria, nome, icone')
          .order('nome');

      final list = (rows as List)
          .map((r) => Categoria.fromJson(r as Map<String, dynamic>))
          .toList();

      _memoryCache = list;
      await _persist(rows.cast<Map<String, dynamic>>());
      return list;
    } catch (e) {
      final cached = await _loadFromCache();
      if (cached.isNotEmpty) {
        _memoryCache = cached;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _persist(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(rows));
  }

  Future<List<Categoria>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((r) => Categoria.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
