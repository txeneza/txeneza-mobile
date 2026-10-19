import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
        'q': 'Como posso submeter uma denúncia de resíduos?',
        'a': 'Para submeter uma denúncia, basta aceder ao separador "Início" (Mapa), tocar no botão flutuante da câmara, captar uma fotografia focada no foco de lixo, adicionar uma descrição informativa e confirmar. A localização geográfica exata é calculada automaticamente através do GPS do dispositivo.'
      },
      {
        'q': 'O que acontece após o envio de uma denúncia?',
        'a': 'A sua denúncia é registada na base de dados municipal e encaminhada para a equipa de limpeza urbana e saneamento da Cidade da Beira. O estado da ocorrência é atualizado de "Pendente" para "Resolvida" assim que as operações de recolha forem finalizadas.'
      },
      {
        'q': 'Como funciona a verificação fotográfica de resolução?',
        'a': 'Quando os serviços municipais concluem a limpeza no local reportado, anexam uma fotografia de comprovação. O morador recebe uma notificação na aplicação e pode comparar as fotografias de antes e depois, aprovando a resolução ou contestando caso o problema subsista.'
      },
      {
        'q': 'A aplicação funciona sem ligação à internet?',
        'a': 'Sim. O Txeneza dispõe de uma arquitetura offline completa. Caso esteja sem rede, as denúncias e ações são guardadas com segurança no armazenamento local do dispositivo e sincronizadas de forma automática assim que a ligação à internet for restabelecida.'
      },
      {
        'q': 'Como posso atualizar o meu bairro de residência?',
        'a': 'Pode alterar o seu bairro a qualquer momento acedendo ao separador Perfil, selecionando o novo bairro na lista oficial dos 31 bairros da Beira e premindo o botão para guardar as alterações.'
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
            'Consulte as respostas para as dúvidas mais comuns sobre o funcionamento da plataforma Txeneza.',
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
