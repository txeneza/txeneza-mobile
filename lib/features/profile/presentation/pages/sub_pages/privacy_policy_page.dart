import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/spacing/app_spacing.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Última atualização: 29 de Junho de 2026',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '1. Introdução',
              content:
                  'A Txeneza valoriza a sua privacidade. Esta Política de Privacidade explica como recolhemos, usamos, divulgamos e protegemos as suas informações ao utilizar o nosso aplicativo móvel concebido para a gestão e reporte de resíduos na Cidade da Beira.',
              isDark: isDark,
            ),
            _buildSection(
              title: '2. Informações que Recolhemos',
              content:
                  'Recolhemos informações fornecidas diretamente por si (como nome, endereço de e-mail, número de celular e bairro de residência) e dados geográficos exatos quando submete uma denúncia através do mapa, de modo a identificar com precisão os focos de lixo.',
              isDark: isDark,
            ),
            _buildSection(
              title: '3. Utilização dos Dados',
              content:
                  'Os seus dados são utilizados para:\n• Processar e encaminhar as denúncias de resíduos aos serviços municipais responsáveis.\n• Fornecer atualizações sobre o estado das suas denúncias.\n• Personalizar a sua experiência no aplicativo e gerir a gamificação (níveis e medalhas).\n• Facilitar o suporte técnico do aplicativo.',
              isDark: isDark,
            ),
            _buildSection(
              title: '4. Partilha de Informações',
              content:
                  'Não vendemos os seus dados a terceiros. As informações relativas às ocorrências e à localização são partilhadas exclusivamente com as autoridades municipais parceiras e serviços de limpeza urbana para efeitos de resolução dos problemas de saneamento reportados.',
              isDark: isDark,
            ),
            _buildSection(
              title: '5. Segurança',
              content:
                  'Implementamos medidas de segurança técnicas e organizacionais para proteger as suas informações contra acessos não autorizados, alteração, divulgação ou destruição acidental.',
              isDark: isDark,
            ),
            _buildSection(
              title: '6. Seus Direitos (GDPR/LGPD)',
              content:
                  'Tem o direito de aceder, retificar ou eliminar os seus dados pessoais a qualquer momento. Para exercer esses direitos, aceda à secção correspondente na sua área de perfil ou contacte o nosso suporte técnico.',
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: isDark ? AppColors.grey300 : AppColors.grey800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
