/// Modelo de notificação para morador.
class NotificacaoModel {
  final String id;
  final String idUtilizador;
  final String? idOcorrencia;
  final String titulo;
  final String mensagem;
  final bool lida;
  final String tipo;
  final DateTime dataHora;

  const NotificacaoModel({
    required this.id,
    required this.idUtilizador,
    this.idOcorrencia,
    required this.titulo,
    required this.mensagem,
    this.lida = false,
    required this.tipo,
    required this.dataHora,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      id: json['id_notificacao'] as String? ?? json['id'] as String? ?? '',
      idUtilizador: json['id_utilizador'] as String? ?? '',
      idOcorrencia: json['id_ocorrencia'] as String?,
      titulo: json['titulo'] as String? ?? 'Notificação Txeneza',
      mensagem: json['mensagem'] as String? ?? '',
      lida: json['lida'] as bool? ?? false,
      tipo: json['tipo'] as String? ?? 'mudanca_estado',
      dataHora: json['data_hora'] != null
          ? DateTime.tryParse(json['data_hora'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_notificacao': id,
        'id_utilizador': idUtilizador,
        'id_ocorrencia': idOcorrencia,
        'titulo': titulo,
        'mensagem': mensagem,
        'lida': lida,
        'tipo': tipo,
        'data_hora': dataHora.toIso8601String(),
      };

  NotificacaoModel copyWith({bool? lida}) {
    return NotificacaoModel(
      id: id,
      idUtilizador: idUtilizador,
      idOcorrencia: idOcorrencia,
      titulo: titulo,
      mensagem: mensagem,
      lida: lida ?? this.lida,
      tipo: tipo,
      dataHora: dataHora,
    );
  }
}
