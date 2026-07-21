import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../occurrence/presentation/pages/resolucao_verification_page.dart';
import '../../data/notificacao_datasource.dart';
import '../../domain/notificacao_model.dart';
import '../widgets/notification_tile.dart';

/// Ecrã de centro de notificações do morador.
///
/// Só lê e marca como lida — nunca cria notificações (isso é sempre feito
/// pelo backend web). Se a leitura falhar (sem rede, RLS mal configurado,
/// etc.), mostra um estado vazio/discreto em vez de quebrar o ecrã.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _dataSource = NotificacaoDataSource();
  List<NotificacaoModel> _notificacoes = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _dataSource.fetchNotificacoes();
      if (!mounted) return;
      setState(() {
        _notificacoes = result;
        _isLoading = false;
      });
    } catch (_) {
      // fetchNotificacoes() já trata os próprios erros e devolve lista
      // vazia; este catch é só uma rede de segurança adicional para nunca
      // deixar o ecrã quebrar.
      if (!mounted) return;
      setState(() {
        _notificacoes = [];
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _onTapNotificacao(NotificacaoModel notif) async {
    if (!notif.lida) {
      // Actualização optimista: marca como lida no ecrã já, e só depois
      // confirma no servidor — sente-se instantâneo mesmo com rede lenta.
      setState(() {
        final idx = _notificacoes.indexWhere((n) => n.id == notif.id);
        if (idx != -1) _notificacoes[idx] = notif.copyWith(lida: true);
      });
      unawaited(_dataSource.marcarComoLida(notif.id));
    }

    // Notificação sem ocorrência associada (ex: aviso geral): fica clicável
    // só para marcar como lida, sem navegação.
    if (notif.idOcorrencia == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResolucaoVerificationPage(
          occurrenceId: notif.idOcorrencia!,
          occurrenceTitle: 'Ocorrência',
        ),
      ),
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
              child: const Text(
                'Marcar tudo como lido',
                style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.forestGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
            : _notificacoes.isEmpty
                ? _buildEmptyState(isDark)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      if (_hasError)
                        _buildErrorBanner(isDark),
                      if (naoLidas.isNotEmpty) ...[
                        _buildSectionHeader('Não lidas', isDark),
                        ...naoLidas.map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: NotificationTile(
                              notificacao: n,
                              isDark: isDark,
                              onTap: () => _onTapNotificacao(n),
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
