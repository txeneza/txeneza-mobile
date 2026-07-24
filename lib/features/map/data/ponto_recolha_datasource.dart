import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/ponto_recolha_model.dart';

/// Lê os pontos de recolha criados pelos administradores no painel web.
/// A app móvel nunca escreve nesta tabela.
class PontoRecolhaDataSource {
  static const String _cacheKey = 'pontos_recolha_cache';

  SupabaseClient get _client => Supabase.instance.client;

  /// Devolve apenas os pontos activos — os inactivos foram desligados pelo
  /// admin e não devem aparecer no mapa. Se a chamada falhar por falta de
  /// internet, carrega do cache local.
  Future<List<PontoRecolha>> fetchActivos() async {
    try {
      final rows = await _client
          .from('ponto_recolha')
          .select('id_ponto, nome, latitude, longitude, bairro, horario')
          .eq('estado', 'activo')
          .order('nome');

      // Salva no cache local de forma assíncrona
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_cacheKey, jsonEncode(rows));
      }).catchError((e) {
        debugPrint('Erro ao guardar cache de pontos de recolha: $e');
      });

      return (rows as List)
          .map((row) => PontoRecolha.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Falha ao carregar pontos de recolha do Supabase ($e). A carregar cache local...');
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_cacheKey);
        if (raw != null) {
          final decoded = jsonDecode(raw) as List;
          return decoded
              .map((row) => PontoRecolha.fromJson(row as Map<String, dynamic>))
              .toList();
        }
      } catch (cacheErr) {
        debugPrint('Erro ao carregar cache de pontos de recolha: $cacheErr');
      }
      return [];
    }
  }
}
