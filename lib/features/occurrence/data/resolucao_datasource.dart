import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/resolucao_verificacao.dart';

/// Datasource Supabase para o ciclo de verificação fotográfica pelo morador.
class ResolucaoDataSource {
  static const String _bucket = 'denuncias';
  SupabaseClient get _client => Supabase.instance.client;

  /// Obtém a verificação e fotos associadas a uma ocorrência.
  Future<ResolucaoVerificacao> fetchVerificacao(String idOcorrencia) async {
    final photos = await _client
        .from('fotografia')
        .select('caminho_ficheiro, tipo')
        .eq('id_ocorrencia', idOcorrencia);

    String? fotoInicialPath;
    String? fotoResolucaoPath;

    for (final row in (photos as List)) {
      final tipo = row['tipo'] as String?;
      final path = row['caminho_ficheiro'] as String?;
      if (path != null) {
        if (tipo == 'denuncia') {
          fotoInicialPath = path;
        } else if (tipo == 'resolucao') {
          fotoResolucaoPath = path;
        }
      }
    }

    final occ = await _client
        .from('ocorrencia')
        .select('data_hora_sync, observacoes, verificacao_morador, observacoes_morador')
        .eq('id_ocorrencia', idOcorrencia)
        .maybeSingle();

    final String? urlInicial = fotoInicialPath != null
        ? _client.storage.from(_bucket).getPublicUrl(fotoInicialPath)
        : null;
    final String? urlResolucao = fotoResolucaoPath != null
        ? _client.storage.from(_bucket).getPublicUrl(fotoResolucaoPath)
        : null;

    return ResolucaoVerificacao(
      idOcorrencia: idOcorrencia,
      fotoInicialUrl: urlInicial,
      fotoResolucaoUrl: urlResolucao,
      dataResolucao: occ != null && occ['data_hora_sync'] != null
          ? DateTime.tryParse(occ['data_hora_sync'] as String)
          : null,
      observacoesEquipa: occ?['observacoes'] as String?,
      statusVerificacao: StatusVerificacaoMorador.fromDb(
          occ?['verificacao_morador'] as String?),
      observacoesMorador: occ?['observacoes_morador'] as String?,
    );
  }

  /// Submete a decisão do morador (aprovar ou contestar com foto opcional).
  Future<void> submitVerificacao({
    required String idOcorrencia,
    required bool aprovado,
    String? observacoes,
    String? fotoContestacaoLocalPath,
  }) async {
    final statusStr = aprovado ? 'aprovado' : 'rejeitado';
    String? contestacaoStoragePath;

    if (!aprovado && fotoContestacaoLocalPath != null) {
      final file = File(fotoContestacaoLocalPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final userId = _client.auth.currentUser?.id ?? 'anonymous';
        contestacaoStoragePath = 'contestacoes/$userId/${idOcorrencia}_contestacao.jpg';

        await _client.storage.from(_bucket).uploadBinary(
              contestacaoStoragePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        await _client.from('fotografia').upsert({
          'id_fotografia': '${idOcorrencia}_contestacao',
          'id_ocorrencia': idOcorrencia,
          'caminho_ficheiro': contestacaoStoragePath,
          'tipo': 'contestacao',
          'data_hora': DateTime.now().toIso8601String(),
        });
      }
    }

    final payload = <String, dynamic>{
      'verificacao_morador': statusStr,
      'observacoes_morador': observacoes,
    };

    if (!aprovado) {
      // Se contestado, o estado da ocorrência volta para em_analise/reaberta
      payload['estado'] = 'reaberta';
    }

    await _client.from('ocorrencia').update(payload).eq('id_ocorrencia', idOcorrencia);
  }
}
