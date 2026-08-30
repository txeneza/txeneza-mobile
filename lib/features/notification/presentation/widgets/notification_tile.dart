import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/notificacao_model.dart';

class _TipoVisual {
  final IconData icon;
  final Color color;
  final String titulo;

  const _TipoVisual(this.icon, this.color, this.titulo);
}

_TipoVisual _visualParaTipo(String tipo, String mensagem) {
  final isCritica = tipo == 'alerta_critico' ||
      mensagem.toLowerCase().contains('crítica') ||
      mensagem.toLowerCase().contains('critica');

  if (isCritica) {
    return const _TipoVisual(
      LucideIcons.octagonAlert,
      AppColors.error,
      'Alerta crítico',
    );
  }

  switch (tipo) {
    case 'reabertura_automatica':
      return const _TipoVisual(
        LucideIcons.triangleAlert,
        AppColors.warning,
        'Ocorrência reaberta',
      );
    case 'resolucao_validada':
    case 'verificacao':
      return const _TipoVisual(
        LucideIcons.circleCheck,
        AppColors.success,
        'Resolução validada',
      );
    case 'nova_denuncia':
    case 'ocorrencia':
      return const _TipoVisual(
        LucideIcons.mapPin,
        AppColors.forestGreen,
        'Nova denúncia',
      );
    case 'alteracao_estado':
      return const _TipoVisual(
        LucideIcons.refreshCw,
        AppColors.info,
        'Ocorrência atualizada',
      );
    default:
      return const _TipoVisual(
        LucideIcons.info,
        AppColors.info,
        'Notificação',
      );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificacaoModel notificacao;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isDark;

  const NotificationTile({
    super.key,
    required this.notificacao,
    required this.onTap,
    this.onDelete,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Higieniza mensagens antigas removendo emojis
    final cleanMensagem = notificacao.mensagem
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '')
        .trim();

    final visual = _visualParaTipo(notificacao.tipo, cleanMensagem);
    final naoLida = !notificacao.lida;

    return Dismissible(
      key: Key(notificacao.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: naoLida
                ? (isDark
                    ? DarkColors.accent.withValues(alpha: 0.10)
                    : AppColors.mintGreen.withValues(alpha: 0.20))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: naoLida
                ? Border.all(
                    color: isDark
                        ? DarkColors.accent.withValues(alpha: 0.20)
                        : AppColors.forestGreen.withValues(alpha: 0.15),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.color, size: 18),
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
                            visual.titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: naoLida ? FontWeight.w800 : FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                        ),
                        if (naoLida)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: BoxDecoration(
                              color: isDark ? DarkColors.accent : AppColors.forestGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cleanMensagem,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppColors.grey800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 11,
                          color: isDark ? Colors.white38 : AppColors.grey600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tempoRelativo(notificacao.dataHora),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (notificacao.idOcorrencia != null) ...[
                          const SizedBox(width: 10),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 11,
                            color: isDark ? DarkColors.accent : AppColors.forestGreen,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Ver detalhes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? DarkColors.accent : AppColors.forestGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
