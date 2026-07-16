import 'package:latlong2/latlong.dart';

/// Ponto de recolha de resíduos, gerido pelos administradores no painel web.
/// Só de leitura na app móvel.
class PontoRecolha {
  final String id;
  final String nome;
  final LatLng position;
  final String bairro;
  final String? horario;

  const PontoRecolha({
    required this.id,
    required this.nome,
    required this.position,
    required this.bairro,
    this.horario,
  });

  factory PontoRecolha.fromJson(Map<String, dynamic> json) {
    // latitude/longitude são DECIMAL(10,7): o PostgREST devolve-os como String
    // ou num, por isso normalizamos via toString() antes de converter.
    return PontoRecolha(
      id: json['id_ponto'] as String,
      nome: json['nome'] as String,
      position: LatLng(
        double.parse(json['latitude'].toString()),
        double.parse(json['longitude'].toString()),
      ),
      bairro: json['bairro'] as String,
      horario: json['horario'] as String?,
    );
  }
}
