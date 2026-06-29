import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/spacing/app_spacing.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Contacto',
          style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.forestGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'Tem alguma dúvida, sugestão ou deseja estabelecer uma parceria de limpeza municipal na Cidade da Beira? Entre em contacto connosco.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: isDark ? AppColors.grey300 : AppColors.grey600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _buildContactCard(
              icon: LucideIcons.mail,
              title: 'E-mail de Suporte',
              value: 'suporte@txeneza.com',
              subtitle: 'Resposta em até 24 horas úteis',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: LucideIcons.phone,
              title: 'Contacto Telefónico',
              value: '+258 84 123 4567',
              subtitle: 'Disponível de segunda a sexta, das 8h às 17h',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: LucideIcons.mapPin,
              title: 'Sede Administrativa',
              value: 'Avenida da Independência, Beira, Moçambique',
              subtitle: 'Conselho Municipal da Cidade da Beira',
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Txeneza Beira Sustentável v1.0.0',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.grey600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Card(
      color: isDark ? const Color(0xFF1E2F2C) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.grey200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.grey600,
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
