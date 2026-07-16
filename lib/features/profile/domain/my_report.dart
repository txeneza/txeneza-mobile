import 'package:flutter/material.dart';

/// Uma ocorrência do próprio utilizador, com foto e estado, para o ecrã
/// "Minhas Ocorrências".
class MyReport {
  final String id;
  final String? photoUrl;
  final String categoria;
  final String descricao;
  final double latitude;
  final double longitude;

  /// Valor do enum EstadoOcorrencia: pendente, em_analise, resolvida, reaberta.
  final String estado;

  /// Valor do enum Gravidade: baixa, media, alta, critica.
  final String gravidade;
  final DateTime dataHora;

  const MyReport({
    required this.id,
    required this.photoUrl,
    required this.categoria,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.estado,
    required this.gravidade,
    required this.dataHora,
  });

  String get coordenadas =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  String get estadoLabel {
    switch (estado) {
      case 'em_analise':
        return 'Em análise';
      case 'resolvida':
        return 'Resolvida';
      case 'reaberta':
        return 'Reaberta';
      case 'pendente':
      default:
        return 'Pendente';
    }
  }

  Color get estadoColor {
    switch (estado) {
      case 'em_analise':
        return const Color(0xFF1565C0); // Azul
      case 'resolvida':
        return const Color(0xFF2E9E5B); // Verde
      case 'reaberta':
        return const Color(0xFFE53935); // Vermelho
      case 'pendente':
      default:
        return const Color(0xFFF57C00); // Laranja
    }
  }

  String get gravidadeLabel {
    switch (gravidade) {
      case 'baixa':
        return 'Baixa';
      case 'alta':
        return 'Alta';
      case 'critica':
        return 'Crítica';
      case 'media':
      default:
        return 'Média';
    }
  }

  /// Data curta em português, ex.: "16 Jul 2026".
  String get dataFormatada {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final d = dataHora.toLocal();
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}
