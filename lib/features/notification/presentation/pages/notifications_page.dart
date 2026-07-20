import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../occurrence/presentation/pages/resolucao_verification_page.dart';
import '../../data/notificacao_datasource.dart';
import '../../domain/notificacao_model.dart';

/// Ecrã de centro de notificações do morador.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _dataSource = NotificacaoDataSource();
  List<NotificacaoModel> _notificacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificacoes();
  }

  Future<void> _loadNotificacoes() async {
    setState(() => _isLoading = true);
    await _dataSource.checkStatusChangesAndNotify();
    final items = await _dataSource.fetchNotificacoes();
    if (!mounted) return;
    setState(() {
      _notificacoes = items;
      _isLoading = false;
    });
  }

  Future<void> _onNotificationTap(NotificacaoModel notif) async {
    if (!notif.lida) {
      await _dataSource.marcarComoLida(notif.id);
      _loadNotificacoes();
    }

    if (notif.idOcorrencia != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResolucaoVerificationPage(
            occurrenceId: notif.idOcorrencia!,
            occurrenceTitle: notif.titulo,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificações',
          style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _loadNotificacoes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
          : _notificacoes.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notificacoes.length,
                  itemBuilder: (context, index) {
                    final item = _notificacoes[index];
                    return _NotificationCard(
                      notification: item,
                      isDark: isDark,
                      onTap: () => _onNotificationTap(item),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Será notificado aqui sempre que o estado das suas denúncias for atualizado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: isDark ? Colors.white60 : AppColors.grey800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificacaoModel notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.lida;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: unread
            ? AppColors.forestGreen.withValues(alpha: isDark ? 0.2 : 0.08)
            : (isDark ? DarkColors.surface : AppColors.grey100),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.bellRing,
                    size: 18,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.titulo,
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 13.5,
                                fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.grey900,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.forestGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.mensagem,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark ? Colors.white70 : AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDataHora(notification.dataHora),
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDataHora(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
