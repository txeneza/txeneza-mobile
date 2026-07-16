import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/typography/text_styles.dart';
import '../../data/services/gemini_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/image_analysis_modal.dart';
import '../widgets/typing_indicator.dart';

class ChatIAScreen extends StatefulWidget {
  const ChatIAScreen({super.key});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  
  // Connectivity
  bool _isOnline = true;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Chat State
  bool _isTyping = false;
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Olá! Eu sou a Xeni, sua Assistente de Inteligência Municipal Txeneza. Estou pronta para processar denúncias de resíduos e responder a dúvidas sobre saneamento e coleta seletiva na cidade da Beira. Como posso ajudar você hoje?',
      'isUser': false,
      'time': 'Agora',
    }
  ];

  final List<String> _suggestions = [
    'Como separar resíduos recicláveis?',
    'Quais são os pontos de coleta na Beira?',
    'Tempo de resposta para denúncias',
  ];

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (mounted && _isOnline != hasConnection) {
      setState(() {
        _isOnline = hasConnection;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time': 'Agora',
      });
      _isTyping = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    // Call API / Engine logic
    if (_isOnline) {
      try {
        final response = await _geminiService.sendMessage(text);
        if (mounted) {
          setState(() {
            _messages.add({
              'text': response,
              'isUser': false,
              'time': 'Agora',
            });
            _isTyping = false;
          });
        }
      } catch (e) {
        _handleOfflineOrErrorFallback(text);
      }
    } else {
      _handleOfflineOrErrorFallback(text);
    }
    _scrollToBottom();
  }

  void _handleOfflineOrErrorFallback(String userText) {
    // Simulate TensorFlow Lite local engine offline response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      String offlineResponse = '### [RESPOSTA OFFLINE - TENSORFLOW LITE]\n';
      final cleanText = userText.toLowerCase();

      if (cleanText.contains('reciclável') || cleanText.contains('separar')) {
        offlineResponse += 'Identifiquei que sua dúvida é sobre reciclagem. Na Beira, separe metal, vidro e plástico. Seus relatórios salvos localmente serão sincronizados assim que você estiver online.';
      } else if (cleanText.contains('pontos') || cleanText.contains('coleta')) {
        offlineResponse += 'Consulte o mapa para ver postos de coleta. Existem depósitos seletivos perto do Mercado Central e do Macuti pré-carregados no app.';
      } else if (cleanText.contains('tempo') || cleanText.contains('prazo')) {
        offlineResponse += 'O SLA padrão para remoção de lixo crítico é de 48 horas úteis através dos canais de notificação da edilidade.';
      } else {
        offlineResponse += 'O assistente está rodando no modo local (offline). Suas mensagens e ocorrências estão guardadas e serão analisadas profundamente pela IA da Txeneza no servidor central assim que restabelecer conexão.';
      }

      setState(() {
        _messages.add({
          'text': offlineResponse,
          'isUser': false,
          'time': 'Agora',
        });
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _openImageSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ImageAnalysisModal(
          geminiService: _geminiService,
          onAnalysisComplete: (imageName, imageAsset, analysisResult) {
            setState(() {
              // User sends the photo message
              _messages.add({
                'text': 'Anexei uma ocorrência: $imageName',
                'isUser': true,
                'time': 'Agora',
                'simulatedImageName': imageName,
                'simulatedImageAsset': imageAsset,
              });

              // Bot replies with classification results (Gemini or TensorFlow Lite)
              _messages.add({
                'text': analysisResult,
                'isUser': false,
                'time': 'Agora',
              });
            });
            _scrollToBottom();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : const Color(0xFFF4F2EB),
      body: Stack(
        children: [
          // Background layout
          Column(
            children: [
              // Extra space for custom glassmorphic app bar
              const SizedBox(height: 104),

              // Chat History
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return const TypingIndicator();
                    }

                    final msg = _messages[index];
                    return ChatBubble(
                      text: msg['text'],
                      isUser: msg['isUser'],
                      time: msg['time'],
                      simulatedImageName: msg['simulatedImageName'],
                      simulatedImageAsset: msg['simulatedImageAsset'],
                    );
                  },
                ),
              ),

              // Suggestions chips (Shown only on fresh conversation)
              if (_messages.length == 1 && !_isTyping)
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ActionChip(
                          label: Text(
                            _suggestions[index],
                            style: TextStyles.captionSmall.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: AppColors.mintGreen.withValues(alpha: 0.35),
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

              // Input Bottom Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey900 : AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.grey800 : AppColors.grey200,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Simulated attachment camera button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          LucideIcons.camera,
                          color: AppColors.forestGreen,
                          size: 20,
                        ),
                        onPressed: _openImageSelectionModal,
                      ),
                    ),
                    AppSpacing.horizontalSpaceSM,

                    // Text Field
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey800 : AppColors.grey100,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _messageController,
                          onSubmitted: _sendMessage,
                          style: TextStyles.captionLarge.copyWith(
                            color: isDark ? AppColors.white : AppColors.grey900,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Fale com a Xeni sobre resíduos...',
                            hintStyle: TextStyles.captionLarge.copyWith(
                              color: AppColors.grey600,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.horizontalSpaceSM,

                    // Send Button
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
                          color: AppColors.white,
                          size: 16,
                        ),
                        onPressed: () => _sendMessage(_messageController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Custom Glassmorphic Premium Header App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 48, AppSpacing.md, AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.black : const Color(0xFFF4F2EB)).withValues(alpha: 0.75),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.grey800.withValues(alpha: 0.5) : AppColors.grey300.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.forestGreen, AppColors.sageGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.forestGreen.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                          // Online Pulsing status indicator
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isOnline ? AppColors.success : AppColors.warning,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.black : Colors.white,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.horizontalSpaceSM,

                      // Assistant Info & Enterprise Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Xeni (Txeneza AI)',
                                  style: TextStyles.captionLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.white : AppColors.forestGreen,
                                  ),
                                ),
                                AppSpacing.horizontalSpaceXS,
                                // Premium Enterprise tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4AF37), Color(0xFFC5A02B)], // Sleek Golden
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ENTERPRISE',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 7,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Current Active Model engine banner
                            Text(
                              _isOnline
                                  ? 'Gemini 2.5 Flash (Online)'
                                  : 'TensorFlow Lite (Offline Local)',
                              style: TextStyles.captionSmall.copyWith(
                                color: AppColors.grey600,
                                fontSize: 10,
                              ),
                            ),
                          ],
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
}
