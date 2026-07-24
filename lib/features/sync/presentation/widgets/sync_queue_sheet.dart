import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../denuncia/data/denuncia_queue.dart';
import '../../../denuncia/domain/denuncia_draft.dart';

/// Modal para listar e forçar a sincronização de denúncias guardadas no dispositivo (RF-012, RF-013).
class SyncQueueSheet extends StatefulWidget {
  final bool isOnline;
  final VoidCallback? onQueueUpdated;

  const SyncQueueSheet({
    super.key,
    required this.isOnline,
    this.onQueueUpdated,
  });

  static Future<void> show(BuildContext context, {required bool isOnline, VoidCallback? onQueueUpdated}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SyncQueueSheet(isOnline: isOnline, onQueueUpdated: onQueueUpdated),
    );
  }

  @override
  State<SyncQueueSheet> createState() => _SyncQueueSheetState();
}

class _SyncQueueSheetState extends State<SyncQueueSheet> {
  final _queue = DenunciaQueue();
  List<DenunciaDraft> _pendingDrafts = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    final list = await _queue.pending();
    if (!mounted) return;
    setState(() {
      _pendingDrafts = list;
      _isLoading = false;
    });
  }

  Future<void> _syncNow() async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem ligação à internet para sincronizar.', style: TextStyle(fontFamily: 'Geist')),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);
    final count = await _queue.flush(forceResetTentativas: true);
    if (!mounted) return;

    setState(() => _isSyncing = false);
    widget.onQueueUpdated?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? '$count denúncia(s) sincronizada(s) com sucesso!'
              : 'Nenhuma denúncia sincronizada. Tente novamente mais tarde.',
          style: const TextStyle(fontFamily: 'Geist'),
        ),
        backgroundColor: count > 0 ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );

    await _loadPending();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? DarkColors.background : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ocorrências Pendentes',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.forestGreen,
                      ),
                    ),
                    Text(
                      'Fila de sincronização offline-first',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppColors.grey600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.forestGreen),
                  )
                : _pendingDrafts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.circleCheckBig, size: 48, color: AppColors.success),
                            const SizedBox(height: 12),
                            Text(
                              'Tudo sincronizado!',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.grey900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Não há denúncias pendentes no dispositivo.',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 13,
                                color: isDark ? Colors.white60 : AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _pendingDrafts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final draft = _pendingDrafts[index];
                          return _buildDraftCard(draft, isDark);
                        },
                      ),
          ),
          if (_pendingDrafts.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.isOnline && !_isSyncing ? _syncNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.refreshCw, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                widget.isOnline ? 'Sincronizar Agora' : 'Aguardando Ligação...',
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(DenunciaDraft draft, bool isDark) {
    final fileExists = File(draft.fotoPathLocal).existsSync();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: fileExists
                ? Image.file(
                    File(draft.fotoPathLocal),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppColors.grey300,
                    child: const Icon(LucideIcons.imageOff, size: 24, color: AppColors.grey600),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.descricao ?? 'Denúncia com foto e GPS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: AppColors.forestGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${draft.latitude.toStringAsFixed(4)}, ${draft.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
                 const SizedBox(height: 4),
                Text(
                  'Registado: ${draft.dataHoraRegisto.toLocal().hour}:${draft.dataHoraRegisto.toLocal().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.grey600,
                  ),
                ),
                if (draft.ultimoErro != null && draft.tentativas >= 3) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Erro: ${draft.ultimoErro}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10.5,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: draft.tentativas >= 3
                  ? Colors.red.withValues(alpha: 0.12)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              draft.tentativas >= 3 ? 'Falhou' : 'Pendente',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: draft.tentativas >= 3 ? Colors.redAccent : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
