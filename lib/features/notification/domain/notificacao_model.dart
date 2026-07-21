/// Tipos reais de notificação gravados pelo backend web (ver
/// txeneza-web: src/app/api/occurrences/[id]/route.ts e
/// src/app/api/occurrences/[id]/verifications/route.ts). Mantidos como
/// String (não enum fechado) para não partir a leitura se o backend vier
/// a introduzir um tipo novo — qualquer tipo desconhecido cai no
/// tratamento "geral" na UI.
class NotificacaoTipo {
  static const alteracaoEstado = 'alteracao_estado';
  static const resolucaoValidada = 'resolucao_validada';
  static const reaberturaAutomatica = 'reabertura_automatica';
}

/// Modelo de notificação para o morador. Espelha exactamente a tabela
/// "notificacao" (Supabase/Prisma) — a app móvel só lê e marca como lida,
/// nunca cria notificações, por isso este modelo não precisa (nem deve ter)
/// mais campos do que os que o backend realmente grava. Em particular, a
/// tabela não tem coluna "titulo": o título mostrado na UI é derivado do
/// "tipo" (ver NotificacaoTipo e o mapeamento em notification_tile.dart).
class NotificacaoModel {
  final String id;
  final String idUtilizador;
  final String? idOcorrencia;
  final String tipo;
  final String mensagem;
  final bool lida;
  final DateTime dataHora;

  const NotificacaoModel({
    required this.id,
    required this.idUtilizador,
    this.idOcorrencia,
    required this.tipo,
    required this.mensagem,
    this.lida = false,
    required this.dataHora,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      id: json['id_notificacao'] as String? ?? json['id'] as String? ?? '',
      idUtilizador: json['id_utilizador'] as String? ?? '',
      idOcorrencia: json['id_ocorrencia'] as String?,
      tipo: json['tipo'] as String? ?? NotificacaoTipo.alteracaoEstado,
      mensagem: json['mensagem'] as String? ?? '',
      lida: json['lida'] as bool? ?? false,
      dataHora: json['data_hora'] != null
          ? DateTime.tryParse(json['data_hora'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificacaoModel copyWith({bool? lida}) {
    return NotificacaoModel(
      id: id,
      idUtilizador: idUtilizador,
      idOcorrencia: idOcorrencia,
      tipo: tipo,
      mensagem: mensagem,
      lida: lida ?? this.lida,
      dataHora: dataHora,
    );
  }
}
