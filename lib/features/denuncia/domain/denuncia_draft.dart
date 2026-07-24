import 'gravidade.dart';

/// Uma denúncia pronta a submeter ou já em fila offline.
///
/// O [id] é gerado no cliente (uuid) antes de qualquer rede, para que a foto e
/// o registo na fila tenham um identificador estável e para que a inserção em
/// `ocorrencia` seja idempotente mesmo que o sync seja tentado mais que uma vez.
class DenunciaDraft {
  final String id;
  final double latitude;
  final double longitude;
  final String? descricao;
  final String idCategoria;
  final Gravidade gravidade;

  /// Caminho do ficheiro de imagem no dispositivo (pasta de documentos da app).
  final String fotoPathLocal;
  final DateTime dataHoraRegisto;

  /// Controle de tentativas de sincronização em segundo plano.
  final int tentativas;
  final String? ultimoErro;

  const DenunciaDraft({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.descricao,
    required this.idCategoria,
    required this.gravidade,
    required this.fotoPathLocal,
    required this.dataHoraRegisto,
    this.tentativas = 0,
    this.ultimoErro,
  });

  DenunciaDraft copyWith({
    String? fotoPathLocal,
    int? tentativas,
    String? ultimoErro,
  }) {
    return DenunciaDraft(
      id: id,
      latitude: latitude,
      longitude: longitude,
      descricao: descricao,
      idCategoria: idCategoria,
      gravidade: gravidade,
      fotoPathLocal: fotoPathLocal ?? this.fotoPathLocal,
      dataHoraRegisto: dataHoraRegisto,
      tentativas: tentativas ?? this.tentativas,
      ultimoErro: ultimoErro ?? this.ultimoErro,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'descricao': descricao,
        'id_categoria': idCategoria,
        'gravidade': gravidade.dbValue,
        'foto_path_local': fotoPathLocal,
        'data_hora_registo': dataHoraRegisto.toIso8601String(),
        'tentativas': tentativas,
        'ultimo_erro': ultimoErro,
      };

  factory DenunciaDraft.fromJson(Map<String, dynamic> json) {
    return DenunciaDraft(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      descricao: json['descricao'] as String?,
      idCategoria: json['id_categoria'] as String,
      gravidade: Gravidade.fromDb(json['gravidade'] as String),
      fotoPathLocal: json['foto_path_local'] as String,
      dataHoraRegisto: DateTime.parse(json['data_hora_registo'] as String),
      tentativas: json['tentativas'] as int? ?? 0,
      ultimoErro: json['ultimo_erro'] as String?,
    );
  }
}
