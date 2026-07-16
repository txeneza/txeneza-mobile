import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/ponto_recolha_model.dart';

/// Lê os pontos de recolha criados pelos administradores no painel web.
/// A app móvel nunca escreve nesta tabela.
class PontoRecolhaDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  /// Devolve apenas os pontos activos — os inactivos foram desligados pelo
  /// admin e não devem aparecer no mapa.
  Future<List<PontoRecolha>> fetchActivos() async {
    final rows = await _client
        .from('ponto_recolha')
        .select('id_ponto, nome, latitude, longitude, bairro, horario')
        .eq('estado', 'activo')
        .order('nome');

    return (rows as List)
        .map((row) => PontoRecolha.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
