import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/network_info.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/icons/app_icons.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/typography/text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/conversacao_datasource.dart';
import '../../data/services/gemini_service.dart';
import '../../data/user_context_service.dart';
import '../../data/xeni_offline_interactive.dart';
import '../../../denuncia/presentation/denuncia_capture_page.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/image_analysis_modal.dart';
import '../widgets/typing_indicator.dart';

class ChatIAScreen extends StatefulWidget {
  final bool isActive;
  const ChatIAScreen({super.key, this.isActive = true});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final ConversacaoDataSource _conversacao = ConversacaoDataSource();
  final UserContextService _userContextService = UserContextService();
  String? _userContext;

  // Connectivity
  bool _isOnline = true;
  late final StreamSubscription<bool> _connectivitySubscription;

  // Chat State
  bool _isTyping = false;
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Olá! Eu sou a Xeni, a tua Assistente Municipal Txeneza. Estou disponível para tirar dúvidas sobre a app, indicar ecopontos e orientar-te em denúncias de resíduos na Cidade da Beira. Como posso ajudar hoje?',
      'isUser': false,
      'time': 'Agora',
    }
  ];

  final List<String> _suggestions = [
    'Como fazer uma denúncia passo a passo?',
    'Onde estão os ecopontos oficiais na Beira?',
    'Como funciona a fila offline e o mapa?',
  ];

  List<XeniOfflineOption> _currentOfflineOptions = XeniOfflineInteractive.mainMenuOptions;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _loadHistory();
    _loadUserContext();
    _connectivitySubscription = NetworkInfo().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void didUpdateWidget(covariant ChatIAScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _scrollToBottom();
    }
  }

  /// Busca uma vez, ao abrir o chat, um resumo do utilizador (nome +
  /// actividade) para dar contexto à Xeni. Falha em silêncio — sem
  /// contexto, a Xeni simplesmente continua a conversar normalmente, só
  /// sem saber o nome/actividade do utilizador.
  Future<void> _loadUserContext() async {
    final context = await _userContextService.buildContextSummary();
    if (!mounted) return;
    setState(() => _userContext = context);
  }

  /// Carrega o histórico guardado no Supabase e acrescenta-o após a saudação.
  Future<void> _loadHistory() async {
    try {
      final turnos = await _conversacao.fetchHistory();
      if (!mounted || turnos.isEmpty) return;
      setState(() {
        for (final t in turnos) {
          final hora = _formatHora(t.dataHora);
          if (t.mensagemUtilizador.isNotEmpty) {
            _messages.add({
              'text': t.mensagemUtilizador,
              'isUser': true,
              'time': hora,
            });
          }
          if (t.respostaXeni.isNotEmpty) {
            _messages.add({
              'text': t.respostaXeni,
              'isUser': false,
              'time': hora,
            });
          }
        }
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Falha ao carregar histórico da conversa: $e');
    }
  }

  void _startNewConversation() {
    setState(() {
      _messages.clear();
      _messages.add({
        'text': 'Olá! Eu sou a Xeni, a tua Assistente Municipal Txeneza. Estou disponível para tirar dúvidas sobre a app, indicar ecopontos e orientar-te em denúncias de resíduos na Cidade da Beira. Como posso ajudar hoje?',
        'isUser': false,
        'time': 'Agora',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nova conversa iniciada.', style: TextStyle(fontFamily: 'Geist')),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmClearHistory(bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.grey900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Limpar Histórico',
          style: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'Tem a certeza de que deseja apagar todo o histórico de conversas do servidor? Esta ação não pode ser desfeita.',
          style: TextStyle(
            fontFamily: 'Geist',
            color: isDark ? Colors.white70 : AppColors.grey800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Geist',
                color: isDark ? Colors.white38 : AppColors.grey600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Apagar tudo',
              style: TextStyle(
                fontFamily: 'Geist',
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isTyping = true;
      });
      try {
        await _conversacao.clearHistory();
        _startNewConversation();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao limpar histórico. Tente novamente.', style: TextStyle(fontFamily: 'Geist')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      }
    }
  }

  String _formatHora(DateTime dt) {
    return formatChatDataHora(dt);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final hasConnection = await NetworkInfo().isConnected;
    _updateConnectionStatus(hasConnection);
  }

  void _updateConnectionStatus(bool hasConnection) {
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

    if (_isOnline) {
      try {
        // Contexto: últimas ~12 mensagens (exclui a atual), para não enviar
        // conversas enormes ao modelo.
        final prior = _messages.sublist(0, _messages.length - 1);
        final history = prior
            .sublist(prior.length > 12 ? prior.length - 12 : 0)
            .where((m) => (m['text'] as String).isNotEmpty)
            .map((m) => ChatTurn(
                  text: m['text'] as String,
                  isUser: m['isUser'] as bool,
                ))
            .toList();

        final response = await _geminiService.sendMessage(
          text,
          history: history,
          userContext: _userContext,
        );
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
          await _simulateTypewriter(response);
        }
        _conversacao.save(mensagem: text, resposta: response);
      } catch (e) {
        final fallback = _getOfflineResponse(text);
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
          await _simulateTypewriter(fallback);
        }
      }
    } else {
      final offlineResponse = _getOfflineResponse(text);
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        await _simulateTypewriter(offlineResponse);
      }
    }
    _scrollToBottom();
  }

  /// Devolve respostas padrão da Xeni para perguntas frequentes quando offline.
  String _getOfflineResponse(String input) {
    return XeniOfflineInteractive.getFallbackResponse(input);
  }

  /// Trata o clique numa opção interativa predefinida no modo offline com sub-árvore de opções.
  Future<void> _onOfflineOptionTap(XeniOfflineOption option) async {
    if (_isTyping) return;
    setState(() {
      _messages.add({
        'text': option.label,
        'isUser': true,
        'time': 'Agora',
      });
      _isTyping = true;
    });
    _scrollToBottom();
    await _simulateTypewriter(option.responseText);
    if (mounted) {
      setState(() {
        _isTyping = false; // Garante que os três pontos (...) desaparecem e liberta a interface!
        if (option.id == 'voltar_menu' || option.followUpOptions == null || option.followUpOptions!.isEmpty) {
          _currentOfflineOptions = XeniOfflineInteractive.mainMenuOptions;
        } else {
          _currentOfflineOptions = option.followUpOptions!;
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _simulateTypewriter(
    String fullText, {
    bool canReport = false,
    String? reportImagePath,
  }) async {
    final Map<String, dynamic> botMessage = {
      'text': '',
      'isUser': false,
      'time': 'Agora',
      'canReport': canReport,
      'reportImagePath': reportImagePath,
    };

    setState(() {
      _messages.add(botMessage);
    });

    final completer = Completer<void>();
    int charIndex = 0;
    final int totalLength = fullText.length;
    const int chunkSize = 6;
    bool autoScrollEnabled = true;

    Timer.periodic(const Duration(milliseconds: 22), (timer) {
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }

      charIndex += chunkSize;
      final isFinished = charIndex >= totalLength;
      final currentText = isFinished ? fullText : fullText.substring(0, charIndex);

      setState(() {
        botMessage['text'] = currentText;
      });

      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        // Se o utilizador subiu para consultar mensagens anteriores, respeita a posição
        if (pos.pixels < (pos.maxScrollExtent - 120)) {
          autoScrollEnabled = false;
        } else if (pos.pixels >= (pos.maxScrollExtent - 60)) {
          autoScrollEnabled = true;
        }

        if (autoScrollEnabled) {
          _scrollController.jumpTo(pos.maxScrollExtent);
        }
      }

      if (isFinished) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  Future<void> _abrirFluxoDenuncia(String imagePath) async {
    final result = await Navigator.of(context).push<DenunciaResult>(
      MaterialPageRoute(
        builder: (_) => DenunciaCapturePage(
          isOnline: _isOnline,
          initialImagePath: imagePath,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (result == DenunciaResult.sentOnline) {
      await _simulateTypewriter(
        'Excelente notícia! A tua denúncia foi submetida com sucesso ao Município da Beira e já está visível no mapa para acompanhamento.',
      );
    } else if (result == DenunciaResult.queuedOffline) {
      await _simulateTypewriter(
        'A tua denúncia foi guardada no telemóvel com segurança e será sincronizada automaticamente assim que tiveres ligação à internet.',
      );
    }
  }

  void _perguntarMaisSobreResiduo(String textoClassificacao) {
    _sendMessage(
      'Podes explicar-me mais sobre o impacto ambiental deste resíduo, o seu tempo de decomposição e como o Txeneza colabora no seu tratamento na Cidade da Beira?',
    );
  }

  void _openImageSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ImageAnalysisModal(
          geminiService: _geminiService,
          onAnalysisComplete: (imagePath, analysisResult) async {
            setState(() {
              // Mensagem do utilizador com a foto real.
              _messages.add({
                'text': 'Foto do resíduo enviada.',
                'isUser': true,
                'time': 'Agora',
                'imagePath': imagePath,
              });
            });
            _scrollToBottom();

            // Resposta de classificação da Xeni com efeito de digitação e botão de denúncia habilitado.
            await _simulateTypewriter(
              analysisResult,
              canReport: true,
              reportImagePath: imagePath,
            );

            // Persiste no histórico (a imagem em si não é guardada nesta tabela).
            _conversacao.save(
              mensagem: 'Foto do resíduo enviada.',
              resposta: analysisResult,
            );
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
      backgroundColor: isDark ? AppColors.grey900 : const Color(0xFFF4F2EB),
      body: Stack(
        children: [
          // Wallpaper SVG da Txeneza
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: isDark ? 0.03 : 0.05,
                child: SvgPicture.asset(
                  AppIcons.logo,
                  width: MediaQuery.of(context).size.width * 0.5,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : AppColors.forestGreen,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

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
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return const TypingIndicator();
                    }

                    final msg = _messages[index];
                    final canReport = msg['canReport'] == true;
                    final reportImagePath = msg['reportImagePath'] as String?;

                    return ChatBubble(
                      text: msg['text'],
                      isUser: msg['isUser'],
                      time: msg['time'],
                      imagePath: msg['imagePath'],
                      canReport: canReport,
                      reportImagePath: reportImagePath,
                      onReport: reportImagePath != null
                          ? () => _abrirFluxoDenuncia(reportImagePath)
                          : null,
                      onLearnMore: () => _perguntarMaisSobreResiduo(msg['text'] as String? ?? ''),
                    );
                  },
                ),
              ),

              // Online Suggestions Chips (Horizontal)
              if (_isOnline && !_isTyping && _messages.length == 1)
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final sugg = _suggestions[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ActionChip(
                          label: Text(
                            sugg,
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
                          onPressed: () => _sendMessage(sugg),
                        ),
                      );
                    },
                  ),
                ),

              // Offline Interactive Options Menu (Vertical Select - Linha a Linha)
              if (!_isOnline && !_isTyping)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          'Selecione um assunto:',
                          style: TextStyles.captionSmall.copyWith(
                            color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 210),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _currentOfflineOptions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final option = _currentOfflineOptions[index];
                            final isReturn = option.id == 'voltar_menu';
                            return InkWell(
                              onTap: () => _onOfflineOptionTap(option),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isReturn
                                      ? AppColors.error.withValues(alpha: isDark ? 0.2 : 0.08)
                                      : (isDark ? AppColors.grey800 : AppColors.mintGreen.withValues(alpha: 0.35)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isReturn
                                        ? AppColors.error.withValues(alpha: 0.4)
                                        : AppColors.sageGreen.withValues(alpha: 0.6),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isReturn ? LucideIcons.arrowLeft : LucideIcons.chevronRight,
                                      size: 16,
                                      color: isReturn ? AppColors.error : AppColors.forestGreen,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: TextStyles.captionLarge.copyWith(
                                          color: isReturn
                                              ? AppColors.error
                                              : (isDark ? AppColors.white : AppColors.forestGreen),
                                          fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),

              // Input Bottom Bar (Desabilitada quando offline)
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
                    // Botão da câmara
                    Opacity(
                      opacity: _isOnline ? 1.0 : 0.4,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkColors.accent.withValues(alpha: 0.15)
                              : AppColors.forestGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.camera,
                            color: isDark ? DarkColors.accent : AppColors.forestGreen,
                            size: 20,
                          ),
                          onPressed: _isOnline ? _openImageSelectionModal : null,
                        ),
                      ),
                    ),
                    AppSpacing.horizontalSpaceSM,

                    // Campo de Texto (Desabilitado no modo offline)
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.surface : AppColors.grey100,
                          borderRadius: BorderRadius.circular(22),
                          border: isDark
                              ? Border.all(
                                  color: DarkColors.accent.withValues(alpha: 0.25),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: TextField(
                          controller: _messageController,
                          enabled: _isOnline,
                          onSubmitted: _isOnline ? _sendMessage : null,
                          style: TextStyles.captionLarge.copyWith(
                            color: isDark ? AppColors.white : AppColors.grey900,
                          ),
                          decoration: InputDecoration(
                            hintText: _isOnline
                                ? 'Fale com a Xeni sobre resíduos...'
                                : 'Modo offline: toque numa opção acima',
                            hintStyle: TextStyles.captionLarge.copyWith(
                              color: isDark ? AppColors.grey400 : AppColors.grey600,
                              fontSize: _isOnline ? 13 : 11.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.horizontalSpaceSM,

                    // Botão Enviar
                    Opacity(
                      opacity: _isOnline ? 1.0 : 0.4,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? (isDark ? DarkColors.accent : AppColors.forestGreen)
                              : AppColors.grey600,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.send,
                            color: _isOnline && isDark ? DarkColors.onAccent : AppColors.white,
                            size: 16,
                          ),
                          onPressed: _isOnline ? () => _sendMessage(_messageController.text) : null,
                        ),
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
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 48, AppSpacing.md, AppSpacing.sm),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.grey900 : const Color(0xFFF4F2EB)).withValues(alpha: 0.95),
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
                                  color: isDark ? AppColors.grey900 : Colors.white,
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
                            Text(
                              _isOnline
                                  ? 'Gemini 2.5 Flash (Online)'
                                  : 'Xeni (Modo Offline)',
                              style: TextStyles.captionSmall.copyWith(
                                color: _isOnline ? AppColors.grey600 : AppColors.warning,
                                fontSize: 10.5,
                                fontWeight: _isOnline ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Menu de Opções
                      PopupMenuButton<String>(
                        icon: Icon(
                          LucideIcons.moreVertical,
                          color: isDark ? AppColors.white : AppColors.forestGreen,
                        ),
                        color: isDark ? AppColors.grey900 : AppColors.white,
                        onSelected: (value) {
                          if (value == 'new') {
                            _startNewConversation();
                          } else if (value == 'clear') {
                            _confirmClearHistory(isDark);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'new',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.messageSquarePlus,
                                  size: 18,
                                  color: isDark ? AppColors.white : AppColors.forestGreen,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Nova Conversa',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    color: isDark ? AppColors.white : AppColors.grey900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'clear',
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Limpar Histórico',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    color: isDark ? AppColors.white : AppColors.grey900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
