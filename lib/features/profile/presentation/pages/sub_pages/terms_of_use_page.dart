import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/spacing/app_spacing.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Termos de Utilização',
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
              title: '1. Aceitação dos Termos',
              content:
                  'Ao utilizar o aplicativo Txeneza, você concorda em cumprir e ser regido por estes Termos de Utilização. Se não concordar com qualquer um dos termos estabelecidos, por favor, não utilize o aplicativo.',
              isDark: isDark,
            ),
            _buildSection(
              title: '2. Registo e Conta',
              content:
                  'Para efetuar denúncias e participar no sistema de gamificação, deve registar uma conta fornecendo dados verídicos e atualizados. Você é responsável por manter a confidencialidade das credenciais de acesso da sua conta.',
              isDark: isDark,
            ),
            _buildSection(
              title: '3. Utilização Correta do Aplicativo',
              content:
                  'O utilizador compromete-se a efetuar reportes verídicos de acumulação irregular de lixo e outros problemas ambientais. É expressamente proibida a submissão de falsos reportes, material ofensivo, conteúdo abusivo ou difamatório nas descrições.',
              isDark: isDark,
            ),
            _buildSection(
              title: '4. Propriedade Intelectual',
              content:
                  'Todos os direitos sobre o design, código-fonte, marcas comerciais e conteúdos contidos no aplicativo Txeneza são de propriedade exclusiva da equipa de desenvolvimento ou do município parceiro.',
              isDark: isDark,
            ),
            _buildSection(
              title: '5. Limitação de Responsabilidade',
              content:
                  'A Txeneza funciona como uma ferramenta de facilitação de comunicação entre o cidadão e os órgãos municipais. Embora trabalhemos para garantir a resolução rápida, não nos responsabilizamos civilmente por eventuais atrasos ou pela não conclusão das limpezas urbanas pelas entidades municipais.',
              isDark: isDark,
            ),
            _buildSection(
              title: '6. Alterações aos Termos',
              content:
                  'Reservamo-nos o direito de alterar estes Termos de Utilização a qualquer momento. Avisaremos os utilizadores através do aplicativo quando ocorrerem alterações significativas.',
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
