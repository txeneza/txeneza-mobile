import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/sqlite_service.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../home/presentation/pages/report_detail_page.dart';
import '../../../occurrence/presentation/pages/resolucao_verification_page.dart';
import '../../../profile/domain/my_report.dart';
import '../../data/notificacao_datasource.dart';
import '../../domain/notificacao_model.dart';
import '../../services/local_notification_service.dart';
import '../widgets/notification_tile.dart';

/// Ecrã de centro de notificações do morador com suporte a SWR e Realtime.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificacaoDataSource _dataSource = NotificacaoDataSource();
  List<NotificacaoModel> _notificacoes = [];
  bool _isLoading = true;
  bool _hasError = false;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadNotificacoes();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = _dataSource.subscribeToChanges(
      userId: userId,
      onChange: () {
        if (mounted) {
          _loadNotificacoes(silently: true);
        }
      },
    )..subscribe();
  }

  Future<void> _loadNotificacoes({bool silently = false}) async {
    if (!silently) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final items = await _dataSource.fetchNotificacoes();
      if (!mounted) return;
      setState(() {
        _notificacoes = items;
        _isLoading = false;
      });
      if (items.every((n) => n.lida)) {
        await LocalNotificationService.cancelAllNotifications();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _onTapNotificacao(NotificacaoModel notif) async {
    if (!notif.lida) {
      setState(() {
        final idx = _notificacoes.indexWhere((n) => n.id == notif.id);
        if (idx != -1) _notificacoes[idx] = notif.copyWith(lida: true);
      });
      unawaited(_dataSource.marcarComoLida(notif.id));
    }

    if (notif.idOcorrencia == null || !mounted) return;

    // 1. Tenta carregar do SQLite L2 local (0ms / offline-first)
    try {
      final localRow = await SqliteService.instance.getOcorrenciaById(notif.idOcorrencia!);
      if (localRow != null && mounted) {
        final report = MyReport(
          id: localRow['id_ocorrencia'] as String,
          photoUrl: localRow['photo_url'] as String?,
          categoria: localRow['nome_categoria'] as String? ?? 'Resíduo',
          descricao: (localRow['descricao'] as String?)?.trim() ?? 'Ocorrência de resíduo reportada.',
          latitude: double.tryParse(localRow['latitude'].toString()) ?? 0,
          longitude: double.tryParse(localRow['longitude'].toString()) ?? 0,
          estado: localRow['estado'] as String? ?? 'pendente',
          gravidade: localRow['gravidade'] as String? ?? 'media',
          dataHora: parseUtcDateTime(localRow['data_hora_registo']),
        );

        if (report.estado == 'resolvida') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResolucaoVerificationPage(
                occurrenceId: report.id,
                occurrenceTitle: report.descricao,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailPage(report: report),
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Fallback de leitura local de ocorrência: $e');
    }

    // 2. Fallback remoto L3 (Supabase)
    try {
      final client = Supabase.instance.client;
      final row = await client
          .from('ocorrencia')
          .select(
            'id_ocorrencia, descricao, latitude, longitude, estado, gravidade, '
            'data_hora_registo, categoria_residuo(nome), '
            'fotografia(caminho_ficheiro, tipo)',
          )
          .eq('id_ocorrencia', notif.idOcorrencia!)
          .maybeSingle();

      if (!mounted) return;

      if (row != null) {
        final report = _mapRowToReport(row, client);

        if (report.estado == 'resolvida') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResolucaoVerificationPage(
                occurrenceId: report.id,
                occurrenceTitle: report.descricao,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailPage(report: report),
            ),
          );
        }
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResolucaoVerificationPage(
              occurrenceId: notif.idOcorrencia!,
              occurrenceTitle: 'Ocorrência',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar detalhes da ocorrência na notificação: $e');
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResolucaoVerificationPage(
            occurrenceId: notif.idOcorrencia!,
            occurrenceTitle: 'Ocorrência',
          ),
        ),
      );
    }
  }

  MyReport _mapRowToReport(Map<String, dynamic> row, SupabaseClient client) {
    final categoria = row['categoria_residuo'] as Map<String, dynamic>?;
    final nomeCategoria = categoria?['nome'] as String? ?? 'Resíduo';
    final descricao = (row['descricao'] as String?)?.trim();

    String? photoUrl;
    final fotos = row['fotografia'] as List?;
    if (fotos != null && fotos.isNotEmpty) {
      final foto = fotos.cast<Map<String, dynamic>>().firstWhere(
            (f) => f['tipo'] == 'denuncia',
            orElse: () => fotos.first as Map<String, dynamic>,
          );
      final path = foto['caminho_ficheiro'] as String?;
      if (path != null && path.isNotEmpty) {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          photoUrl = path;
        } else {
          photoUrl = client.storage.from('denuncias').getPublicUrl(path);
        }
      }
    }

    return MyReport(
      id: row['id_ocorrencia'] as String,
      photoUrl: photoUrl,
      categoria: nomeCategoria,
      descricao: (descricao != null && descricao.isNotEmpty)
          ? descricao
          : 'Ocorrência de resíduo reportada.',
      latitude: double.tryParse(row['latitude'].toString()) ?? 0,
      longitude: double.tryParse(row['longitude'].toString()) ?? 0,
      estado: row['estado'] as String? ?? 'pendente',
      gravidade: row['gravidade'] as String? ?? 'media',
      dataHora: parseUtcDateTime(row['data_hora_registo']),
    );
  }

  Future<void> _marcarTodasComoLidas() async {
    final aindaNaoLidas = _notificacoes.where((n) => !n.lida).toList();
    if (aindaNaoLidas.isEmpty) return;

    setState(() {
      _notificacoes = _notificacoes.map((n) => n.copyWith(lida: true)).toList();
    });
    await _dataSource.marcarTodasComoLidas();
  }

  Future<void> _onDeleteNotificacao(String id) async {
    setState(() {
      _notificacoes.removeWhere((n) => n.id == id);
    });
    await _dataSource.eliminarNotificacao(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final naoLidas = _notificacoes.where((n) => !n.lida).toList();
    final lidas = _notificacoes.where((n) => n.lida).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.grey900 : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.grey900 : AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Notificações',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.grey900),
        actions: [
          if (naoLidas.isNotEmpty)
            TextButton(
              onPressed: _marcarTodasComoLidas,
              child: Text(
                'Marcar tudo como lido',
                style: TextStyle(
                  color: isDark ? DarkColors.accent : AppColors.forestGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotificacoes,
        color: isDark ? DarkColors.accent : AppColors.forestGreen,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: isDark ? DarkColors.accent : AppColors.forestGreen))
            : _notificacoes.isEmpty
                ? _buildEmptyState(isDark)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      if (_hasError)
                        _buildErrorBanner(isDark),
                      if (naoLidas.isNotEmpty) ...[
                        _buildSectionHeader('Não lidas (${naoLidas.length})', isDark),
                        ...naoLidas.map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: NotificationTile(
                              notificacao: n,
                              isDark: isDark,
                              onTap: () => _onTapNotificacao(n),
                              onDelete: () => _onDeleteNotificacao(n.id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (lidas.isNotEmpty) ...[
                        _buildSectionHeader('Lidas', isDark),
                        ...lidas.map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: NotificationTile(
                              notificacao: n,
                              isDark: isDark,
                              onTap: () => _onTapNotificacao(n),
                              onDelete: () => _onDeleteNotificacao(n.id),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: isDark ? Colors.white38 : AppColors.grey600,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Não foi possível atualizar as notificações agora. A puxar para baixo tenta de novo.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.grey800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.bellOff,
                    size: 48,
                    color: isDark ? Colors.white38 : AppColors.grey600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sem notificações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quando o estado de uma denúncia sua mudar, aparece aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : AppColors.grey800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
