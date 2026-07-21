import 'package:flutter/material.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../domain/notificacao_model.dart';

/// Mapeamento ícone/cor/título por tipo de notificação. Espelha
/// deliberadamente o mesmo mapeamento já usado no sino de notificações do
/// painel web (src/components/layout/notification-bell.tsx), para o
/// significado visual (cor = urgência/natureza) ser consistente entre as
/// duas plataformas.
class _TipoVisual {
  final IconData icon;
  final Color color;
  final String titulo;

  const _TipoVisual(this.icon, this.color, this.titulo);
}

_TipoVisual _visualParaTipo(String tipo) {
  switch (tipo) {
    case NotificacaoTipo.reaberturaAutomatica:
      return const _TipoVisual(
        Icons.warning_amber_rounded,
        AppColors.warning,
        'Ocorrência reaberta',
      );
    case NotificacaoTipo.resolucaoValidada:
      return const _TipoVisual(
        Icons.check_circle_outline_rounded,
        AppColors.success,
        'Resolução validada',
      );
    case NotificacaoTipo.alteracaoEstado:
    default:
      return const _TipoVisual(
        Icons.info_outline_rounded,
        AppColors.info,
        'Ocorrência atualizada',
      );
  }
}

/// Texto de tempo relativo simples, em português ("agora", "há 5 min",
/// "há 2h", "há 3 dias"). Cai para data absoluta (dd/mm) a partir de 7 dias.
String tempoRelativo(DateTime dataHora) {
  final diff = DateTime.now().difference(dataHora);

  if (diff.inSeconds < 60) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours}h';
  if (diff.inDays < 7) return 'há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';

  return '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}';
}

/// Item de lista reutilizável para uma notificação. Usado tanto na secção
/// "Não lidas" como "Lidas" da página de notificações — a única diferença
/// visual entre os dois estados é o destaque (fundo/bolinha) de não lida.
class NotificationTile extends StatelessWidget {
  final NotificacaoModel notificacao;
  final VoidCallback onTap;
  final bool isDark;

  const NotificationTile({
    super.key,
    required this.notificacao,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _visualParaTipo(notificacao.tipo);
    final naoLida = !notificacao.lida;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: naoLida
              ? (isDark
                  ? AppColors.limeGreen.withValues(alpha: 0.08)
                  : AppColors.mintGreen.withValues(alpha: 0.25))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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
              child: Icon(visual.icon, color: visual.color, size: 20),
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
                          decoration: const BoxDecoration(
                            color: AppColors.limeGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notificacao.mensagem,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.grey800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tempoRelativo(notificacao.dataHora),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : AppColors.grey600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
