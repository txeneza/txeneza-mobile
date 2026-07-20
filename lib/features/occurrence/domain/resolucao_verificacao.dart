/// Modelo do ciclo de verificação fotográfica da resolução de uma denúncia.
enum StatusVerificacaoMorador {
  pendente,
  aprovado,
  rejeitado;

  String get dbValue => name;

  static StatusVerificacaoMorador fromDb(String? value) {
    return StatusVerificacaoMorador.values.firstWhere(
      (s) => s.name == value,
      orElse: () => StatusVerificacaoMorador.pendente,
    );
  }
}

class ResolucaoVerificacao {
  final String idOcorrencia;
  final String? fotoInicialUrl;
  final String? fotoResolucaoUrl;
  final DateTime? dataResolucao;
  final String? observacoesEquipa;
  final StatusVerificacaoMorador statusVerificacao;
  final String? observacoesMorador;
  final String? fotoContestacaoUrl;

  const ResolucaoVerificacao({
    required this.idOcorrencia,
    this.fotoInicialUrl,
    this.fotoResolucaoUrl,
    this.dataResolucao,
    this.observacoesEquipa,
    this.statusVerificacao = StatusVerificacaoMorador.pendente,
    this.observacoesMorador,
    this.fotoContestacaoUrl,
  });

  factory ResolucaoVerificacao.fromJson(Map<String, dynamic> json) {
    return ResolucaoVerificacao(
      idOcorrencia: json['id_ocorrencia'] as String,
      fotoInicialUrl: json['foto_inicial_url'] as String?,
      fotoResolucaoUrl: json['foto_resolucao_url'] as String?,
      dataResolucao: json['data_resolucao'] != null
          ? DateTime.tryParse(json['data_resolucao'] as String)
          : null,
      observacoesEquipa: json['observacoes_equipa'] as String?,
      statusVerificacao: StatusVerificacaoMorador.fromDb(
          json['verificacao_morador'] as String?),
      observacoesMorador: json['observacoes_morador'] as String?,
      fotoContestacaoUrl: json['foto_contestacao_url'] as String?,
    );
  }
}
