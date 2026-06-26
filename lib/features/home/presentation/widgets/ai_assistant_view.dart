import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class AIAssistantView extends StatefulWidget {
  const AIAssistantView({super.key});

  @override
  State<AIAssistantView> createState() => _AIAssistantViewState();
}

class _AIAssistantViewState extends State<AIAssistantView> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Olá! Sou o assistente de inteligência artificial da Txeneza. Como posso ajudar você a manter a cidade da Beira mais limpa hoje?',
      'isUser': false,
      'time': 'Agora',
    }
  ];

  final List<String> _suggestions = [
    'Como separar lixo reciclável?',
    'Pontos de coleta na Beira',
    'Prazo de resolução de denúncia',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time': 'Agora',
      });
    });

    _messageController.clear();

    // Simulated automated AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      String aiResponse = 'Obrigado pela sua mensagem! ';
      if (text.contains('reciclável') || text.contains('separar')) {
        aiResponse += 'Na Beira, você pode separar plásticos, vidros e metais. A Txeneza ajuda a notificar os serviços municipais para coleta seletiva dessas categorias.';
      } else if (text.contains('pontos') || text.contains('coleta')) {
        aiResponse += 'Existem contentores de deposição seletiva perto do Mercado Central e na zona costeira do Macuti. Utilize o nosso mapa para visualizar.';
      } else if (text.contains('prazo') || text.contains('tempo')) {
        aiResponse += 'O prazo médio de resolução pela edilidade para ocorrências classificadas como "Críticas" é de 48 horas úteis.';
      } else {
        aiResponse += 'Estou analisando a sua mensagem para fornecer os melhores detalhes sobre saneamento e remoção de resíduos sólidos.';
      }

      setState(() {
        _messages.add({
          'text': aiResponse,
          'isUser': false,
          'time': 'Agora',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Welcome Header Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.forestGreen.withValues(alpha: 0.05),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.sageGreen.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.forestGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assistente Txeneza IA',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    Text(
                      'Respostas inteligentes sobre limpeza e reciclagem.',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: AppColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Chat History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final bool isUser = msg['isUser'];

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.forestGreen
                        : (isDark ? AppColors.grey900 : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark ? AppColors.grey800 : AppColors.grey200,
                            width: 1,
                          ),
                    boxShadow: isUser
                        ? const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ]
                        : const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['text'],
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          color: isUser ? Colors.white : (isDark ? Colors.white : AppColors.grey900),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          msg['time'],
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 10,
                            color: isUser ? Colors.white70 : AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Suggestions Chips (Only shown if user hasn't typed much)
        if (_messages.length == 1)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(
                      _suggestions[index],
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppColors.mintGreen.withValues(alpha: 0.4),
                    side: BorderSide(
                      color: AppColors.sageGreen.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () => _sendMessage(_suggestions[index]),
                  ),
                );
              },
            ),
          ),

        // Text input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.black : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.grey900 : AppColors.grey200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey900 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: _sendMessage,
                    style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Pergunte sobre saneamento...',
                      hintStyle: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.forestGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
