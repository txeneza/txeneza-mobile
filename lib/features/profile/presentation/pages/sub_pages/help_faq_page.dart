import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/spacing/app_spacing.dart';

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final faqItems = [
      {
        'q': 'Como posso fazer uma denúncia?',
        'a': 'Para fazer uma denúncia, basta ir à aba "Início" (Mapa), clicar no botão flutuante "Denunciar", tirar uma fotografia do foco de lixo, adicionar uma descrição opcional e submeter. O local será registrado automaticamente pelo GPS.'
      },
      {
        'q': 'O que acontece após eu enviar uma denúncia?',
        'a': 'A sua denúncia é marcada no mapa municipal e enviada para a equipe de limpeza urbana da Cidade da Beira. O estado da denúncia mudará de "Pendente" para "Resolvido" assim que a recolha e limpeza do local forem concluídas.'
      },
      {
        'q': 'Como ganho pontos e medalhas (badges)?',
        'a': 'Você ganha pontos ao submeter denúncias válidas que ajudam a equipe municipal. Conforme acumula pontos, o seu nível aumenta. Medalhas específicas (como "Guardião Verde") são concedidas ao atingir marcos de denúncias resolvidas.'
      },
      {
        'q': 'O aplicativo funciona sem acesso à internet?',
        'a': 'Sim! O Txeneza possui um modo offline completo. Se estiver offline, pode criar e salvar as suas denúncias localmente no dispositivo. Elas serão sincronizadas automaticamente assim que recuperar a ligação à internet.'
      },
      {
        'q': 'Como posso alterar a minha localização residencial/bairro?',
        'a': 'Pode alterar o seu bairro a qualquer momento acedendo ao seu Perfil, clicando na lista de seleção "Bairro" sob o cartão de dados pessoais e salvando as alterações.'
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ajuda / FAQ',
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Perguntas Frequentes',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.white : AppColors.forestGreen,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Encontre respostas rápidas para as dúvidas mais comuns sobre o uso do aplicativo Txeneza.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: isDark ? AppColors.grey300 : AppColors.grey600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ...faqItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isDark ? const Color(0xFF1E2F2C) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.grey200,
                  width: 1,
                ),
              ),
              child: ExpansionTile(
                iconColor: AppColors.limeGreen,
                collapsedIconColor: isDark ? Colors.white70 : AppColors.forestGreen,
                title: Text(
                  item['q']!,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.forestGreen,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      item['a']!,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color: isDark ? AppColors.grey300 : AppColors.grey800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
