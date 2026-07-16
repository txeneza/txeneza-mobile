import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/icons/app_icons.dart';
import '../../domain/ponto_recolha_model.dart';

/// Verde-floresta da marca (#01403A), a mesma cor dominante do logo.
const Color kPontoRecolhaColor = AppColors.forestGreen;

/// Marcador de ponto de recolha: badge branco com o logo da Txeneza.
///
/// O fundo é branco de propósito — o logo é multicolor (verde-floresta + lima)
/// e num badge colorido perderia contraste. Um badge branco distingue-se também
/// dos pins de ocorrência, que são gotas sólidas coloridas com ícone branco.
class PontoRecolhaMarker extends StatelessWidget {
  final VoidCallback onTap;

  const PontoRecolhaMarker({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: kPontoRecolhaColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: kPontoRecolhaColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          AppIcons.logo,
          height: 20,
        ),
      ),
    );
  }
}

/// Folha de detalhes mostrada ao tocar num ponto de recolha.
void showPontoRecolhaDetails(BuildContext context, PontoRecolha ponto) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final surface = isDark ? DarkColors.surface : Colors.white;

      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kPontoRecolhaColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(AppIcons.logo, height: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ponto.nome,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ponto de recolha oficial',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          // Em fundo escuro o verde-floresta fica ilegível.
                          color: isDark
                              ? AppColors.lightLime
                              : kPontoRecolhaColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: LucideIcons.mapPin,
              label: 'Bairro',
              value: ponto.bairro,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: LucideIcons.clock4,
              label: 'Horário',
              value: ponto.horario?.isNotEmpty == true
                  ? ponto.horario!
                  : 'Não informado',
              isDark: isDark,
            ),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white54 : AppColors.grey600,
        ),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : AppColors.grey600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
        ),
      ],
    );
  }
}
