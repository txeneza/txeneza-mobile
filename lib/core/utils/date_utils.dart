/// Utilitários para tratamento e formatação de datas/horas na aplicação Txeneza Mobile
/// segundo o fuso horário oficial de Maputo, Moçambique (UTC+2).
library;

/// Deslocamento oficial de Moçambique / Maputo (CAT - Central Africa Time, UTC+2).
const Duration maputoOffset = Duration(hours: 2);

/// Converte com segurança qualquer valor de data/hora vindo do Supabase/PostgreSQL
/// para um [DateTime] em UTC.
DateTime parseUtcDateTime(dynamic raw) {
  if (raw == null) return DateTime.now().toUtc();
  if (raw is DateTime) return raw.toUtc();

  final str = raw.toString().trim();
  if (str.isEmpty) return DateTime.now().toUtc();

  String isoStr = str;
  // Se a string ISO não tem indicação de fuso ('Z', '+' ou '-'), assume-se UTC.
  if (!str.endsWith('Z') &&
      !str.contains('+') &&
      !RegExp(r'-\d{2}:?\d{2}$').hasMatch(str)) {
    isoStr = str.contains('T') ? '${str}Z' : '${str.replaceAll(' ', 'T')}Z';
  }

  final parsed =
      DateTime.tryParse(isoStr) ?? DateTime.tryParse(str) ?? DateTime.now();
  return parsed.toUtc();
}

/// Converte um [DateTime] para o fuso horário oficial de Maputo (UTC+2).
DateTime toMaputoTime(DateTime dt) {
  final utc = dt.isUtc ? dt : dt.toUtc();
  return utc.add(maputoOffset);
}

/// Formata a hora no fuso horário de Maputo (ex.: "15:30").
String formatHoraMaputo(DateTime dt) {
  final m = toMaputoTime(dt);
  final h = m.hour.toString().padLeft(2, '0');
  final min = m.minute.toString().padLeft(2, '0');
  return '$h:$min';
}

/// Devolve o texto de tempo relativo em português ("agora", "há 5 min", "há 2h", "há 3 dias").
/// O cálculo é efetuado em UTC para total imunidade a fusos locais desalinhados do dispositivo.
String tempoRelativo(DateTime dataHora) {
  final nowUtc = DateTime.now().toUtc();
  final targetUtc = dataHora.isUtc ? dataHora : dataHora.toUtc();
  final diff = nowUtc.difference(targetUtc);

  if (diff.isNegative || diff.inSeconds < 60) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours}h';
  if (diff.inDays < 7) {
    return 'há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
  }

  final m = toMaputoTime(dataHora);
  final day = m.day.toString().padLeft(2, '0');
  final month = m.month.toString().padLeft(2, '0');
  return '$day/$month';
}

/// Formata a data/hora para mensagens de chat ("17:00", "Ontem às 17:00", "24/07 às 17:00" ou "24/07/2026 às 17:00")
/// referenciada com precisão à hora de Maputo.
String formatChatDataHora(DateTime dt) {
  final nowMaputo = toMaputoTime(DateTime.now());
  final local = toMaputoTime(dt);

  final today = DateTime(nowMaputo.year, nowMaputo.month, nowMaputo.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateOnly = DateTime(local.year, local.month, local.day);

  final hora =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

  if (dateOnly.isAtSameMomentAs(today)) {
    return hora;
  } else if (dateOnly.isAtSameMomentAs(yesterday)) {
    return 'Ontem às $hora';
  } else if (local.year == nowMaputo.year) {
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month às $hora';
  } else {
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year} às $hora';
  }
}
