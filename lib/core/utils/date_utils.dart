/// Utilitários para tratamento e formatação de datas/horas na aplicação Txeneza Mobile.
library;

/// Converte com segurança qualquer valor de data/hora vindo do Supabase/PostgreSQL
/// para a hora local do dispositivo (`toLocal()`).
/// 
/// O PostgreSQL devolve colunas `TIMESTAMP(3)` como strings ISO sem sufixo de fuso horário
/// (ex: `2026-07-25T06:15:00`). Esta função garante que strings sem fuso são tratadas
/// como UTC e convertidas corretamente para a hora local do utilizador (ex: UTC+2 em Moçambique).
DateTime parseUtcDateTime(dynamic raw) {
  if (raw == null) return DateTime.now();
  if (raw is DateTime) return raw.toLocal();

  final str = raw.toString().trim();
  if (str.isEmpty) return DateTime.now();

  String isoStr = str;
  // Se a string ISO não tem indicação de fuso ('Z', '+' ou '-'), assume-se UTC.
  if (!str.endsWith('Z') &&
      !str.contains('+') &&
      !RegExp(r'-\d{2}:?\d{2}$').hasMatch(str)) {
    isoStr = str.contains('T') ? '${str}Z' : '${str.replaceAll(' ', 'T')}Z';
  }

  final parsed =
      DateTime.tryParse(isoStr) ?? DateTime.tryParse(str) ?? DateTime.now();
  return parsed.toLocal();
}

/// Devolve o texto de tempo relativo em português ("agora", "há 5 min", "há 2h", "há 3 dias").
/// Cai para formato de data simples (dd/mm) a partir de 7 dias.
String tempoRelativo(DateTime dataHora) {
  final now = DateTime.now();
  final localDataHora = dataHora.toLocal();
  final diff = now.difference(localDataHora);

  if (diff.isNegative || diff.inSeconds < 60) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours}h';
  if (diff.inDays < 7) {
    return 'há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
  }

  final day = localDataHora.day.toString().padLeft(2, '0');
  final month = localDataHora.month.toString().padLeft(2, '0');
  return '$day/$month';
}

/// Formata a data/hora para mensagens de chat ("17:00", "Ontem às 17:00", "24/07 às 17:00" ou "24/07/2026 às 17:00").
String formatChatDataHora(DateTime dt) {
  final now = DateTime.now();
  final local = dt.toLocal();

  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateOnly = DateTime(local.year, local.month, local.day);

  final hora =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

  if (dateOnly.isAtSameMomentAs(today)) {
    return hora;
  } else if (dateOnly.isAtSameMomentAs(yesterday)) {
    return 'Ontem às $hora';
  } else if (local.year == now.year) {
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month às $hora';
  } else {
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year} às $hora';
  }
}
