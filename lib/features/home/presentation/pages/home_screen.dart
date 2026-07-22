import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../../../core/theme/colors/app_colors.dart';
import '../../../../shared/widgets/layout/app_bar.dart';
import '../../../../shared/widgets/offline_status_banner.dart';
import '../../../denuncia/data/denuncia_queue.dart';
import '../../../denuncia/data/ocorrencia_datasource.dart';
import '../../../denuncia/presentation/denuncia_capture_page.dart';
import '../../../map/data/ponto_recolha_datasource.dart';
import '../../../map/domain/beira_geo.dart';
import '../../../map/domain/occurrence_model.dart';
import '../../../map/domain/ponto_recolha_model.dart';
import '../../../map/presentation/pages/map_page.dart';
import '../../../chatIA/presentation/pages/chat_ia_screen.dart';
import '../../../notification/data/notificacao_datasource.dart';
import '../../../notification/presentation/pages/notifications_page.dart';
import '../../../notification/services/fcm_service.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../sync/presentation/widgets/sync_queue_sheet.dart';
import '../widgets/floating_bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedBottomIndex = 0;

  // Connectivity & Queue state
  bool _isOnline = true;
  bool _isManualOverride = false;
  bool _isFirstConnectivityEvent = true;
  int _pendingCount = 0;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Map state
  mapbox.MapboxMap? _mapboxMap;
  double _currentScale = 12.5;
  bool _isResolvingGps = false;
  // Posição do utilizador: começa no centro da Beira e é atualizada pelo GPS.
  LatLng _userLocation = BeiraGeo.center;

  // Pontos de recolha oficiais, geridos pelos admins no painel web.
  final _pontoRecolhaDataSource = PontoRecolhaDataSource();
  List<PontoRecolha> _pontosRecolha = [];
  bool _showPontosRecolha = true;

  // Ocorrências reais (Supabase) + fila offline de denúncias.
  final _ocorrenciaDataSource = OcorrenciaDataSource();
  final _denunciaQueue = DenunciaQueue();
  List<Occurrence> _occurrences = [];

  // Notificações: contagem de não lidas para o badge do sino, actualizada
  // em tempo real via Supabase Realtime.
  final _notificacaoDataSource = NotificacaoDataSource();
  int _unreadCount = 0;
  RealtimeChannel? _notificacaoChannel;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _loadPontosRecolha();
    _loadOccurrences();
    _flushQueue();
    _recuperarFotoPerdida();
    _loadUnreadCount();
    _subscribeToNotificacoes();
    FCMService.syncToken();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!_isManualOverride) {
        _updateConnectionStatus(results);
      }
    });
  }

  /// Lê as notificações e actualiza a contagem de não lidas mostrada no
  /// badge do sino. Falha em silêncio (mesmo cuidado que o resto do ecrã):
  /// sem rede, o badge simplesmente não actualiza, nunca quebra a home.
  Future<void> _loadUnreadCount() async {
    try {
      final notificacoes = await _notificacaoDataSource.fetchNotificacoes();
      if (!mounted) return;
      setState(() {
        _unreadCount = notificacoes.where((n) => !n.lida).length;
      });
    } catch (e) {
      debugPrint('Falha ao carregar contagem de notificações: $e');
    }
  }

  /// Subscreve alterações em tempo real na tabela "notificacao" — assim que
  /// o backend web cria uma notificação nova (ou o utilizador marca alguma
  /// como lida noutro dispositivo), o badge actualiza-se sozinho, sem
  /// precisar reabrir a app.
  void _subscribeToNotificacoes() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _notificacaoChannel = _notificacaoDataSource.subscribeToChanges(
      userId: userId,
      onChange: _loadUnreadCount,
    )..subscribe();
  }

  Future<void> _onBellTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    // Ao voltar do centro de notificações, o utilizador pode ter lido
    // algumas — reflecte isso no badge.
    _loadUnreadCount();
  }

  /// Em Android, se o sistema matar a app enquanto a câmara está aberta (comum
  /// em dispositivos com pouca memória), a foto tirada fica "perdida". Aqui
  /// recuperamo-la e reabrimos o ecrã de denúncia já com ela, em vez de o
  /// utilizador ficar na home e perder o trabalho.
  Future<void> _recuperarFotoPerdida() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (lost.isEmpty || lost.file == null || !mounted) return;
      await _abrirCaptura(initialImagePath: lost.file!.path);
    } catch (e) {
      debugPrint('Falha ao recuperar foto perdida: $e');
    }
  }

  /// Carrega as ocorrências reais do Supabase. Sem rede, mantém a última lista.
  Future<void> _loadOccurrences() async {
    try {
      final occ = await _ocorrenciaDataSource.fetchAll();
      if (!mounted) return;
      setState(() => _occurrences = occ);
    } catch (e) {
      debugPrint('Falha ao carregar ocorrências: $e');
    }
  }

  /// Sincroniza denúncias em fila offline; se enviar alguma, recarrega o mapa.
  Future<void> _flushQueue() async {
    try {
      final initialCount = await _denunciaQueue.pendingCount();
      if (mounted) setState(() => _pendingCount = initialCount);
      if (!_isOnline) return;

      final enviadas = await _denunciaQueue.flush();
      final remainingCount = await _denunciaQueue.pendingCount();
      if (mounted) {
        setState(() => _pendingCount = remainingCount);
      }
      if (enviadas > 0) {
        await _loadOccurrences();
      }
    } catch (e) {
      debugPrint('Falha ao sincronizar fila de denúncias: $e');
    }
  }

  /// Carrega os pontos de recolha do Supabase. Uma falha aqui não deve estragar
  /// o mapa: sem rede simplesmente não se mostram pontos.
  Future<void> _loadPontosRecolha() async {
    try {
      final pontos = await _pontoRecolhaDataSource.fetchActivos();
      if (!mounted) return;
      // Mostra sempre os dados reais do Supabase. Se não houver pontos
      // activos, a lista fica vazia — nunca inventamos pontos falsos.
      setState(() => _pontosRecolha = pontos);
    } catch (e) {
      debugPrint('Falha ao carregar pontos de recolha: $e');
    }
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (!_isManualOverride) {
      _updateConnectionStatus(results);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (_isOnline != hasConnection || _isFirstConnectivityEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isOnline = hasConnection;
          });
          if (!_isFirstConnectivityEvent) {
            _showConnectivitySnackbar(hasConnection);
            // A ligação voltou: recarrega dados e sincroniza a fila de denúncias.
            if (hasConnection) {
              if (_pontosRecolha.isEmpty) _loadPontosRecolha();
              _loadOccurrences();
              _flushQueue();
            }
          }
          _isFirstConnectivityEvent = false;
        }
      });
    }
  }

  void _toggleConnectivityManually() {
    setState(() {
      _isOnline = !_isOnline;
      _isManualOverride = true;
    });
    _showConnectivitySnackbar(_isOnline);
  }

  void _showConnectivitySnackbar(bool isOnline) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnline
              ? 'Conexão restabelecida. Sincronizando dados em tempo real...'
              : 'Você está offline. Exibindo dados salvos localmente.',
          style: const TextStyle(fontFamily: 'Geist'),
        ),
        backgroundColor: isOnline ? AppColors.forestGreen : const Color(0xFFFB8C00),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    if (_notificacaoChannel != null) {
      Supabase.instance.client.removeChannel(_notificacaoChannel!);
    }
    super.dispose();
  }

  // Smooth map centering animation using Mapbox's native flyTo
  void _animateMapTo(LatLng target, double targetZoom) {
    final map = _mapboxMap;
    if (map == null) return;
    map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(target.longitude, target.latitude)),
        zoom: targetZoom,
      ),
      mapbox.MapAnimationOptions(duration: 900),
    );
  }

  /// GPS real: obtém a posição do dispositivo e centra o mapa nela. Se o GPS
  /// falhar (sem permissão/serviço), recorre ao centro da Beira.
  Future<void> _onLocationPressed() async {
    if (_isResolvingGps) return;
    setState(() => _isResolvingGps = true);

    LatLng target = _userLocation;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          );
          target = LatLng(pos.latitude, pos.longitude);
          _userLocation = target;
        }
      }
    } catch (e) {
      debugPrint('Falha ao obter GPS: $e');
    }

    if (!mounted) return;
    setState(() => _isResolvingGps = false);
    _animateMapTo(target, 15.0);
  }

  /// Abre o fluxo de captura de denúncia. Ao voltar, recarrega o mapa e mostra
  /// feedback consoante o envio tenha sido online ou guardado na fila offline.
  Future<void> _onDenunciarPressed() => _abrirCaptura();

  Future<void> _abrirCaptura({String? initialImagePath}) async {
    final result = await Navigator.of(context).push<DenunciaResult>(
      MaterialPageRoute(
        builder: (_) => DenunciaCapturePage(
          isOnline: _isOnline,
          initialImagePath: initialImagePath,
        ),
      ),
    );
    if (!mounted || result == null) return;

    if (result == DenunciaResult.sentOnline) {
      _showSnack('Denúncia enviada com sucesso!', AppColors.forestGreen);
      _loadOccurrences();
    } else {
      _showSnack(
        'Sem ligação. Denúncia guardada e será sincronizada automaticamente.',
        const Color(0xFFFB8C00),
      );
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Geist')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Handle bottom navigation updates
  void _onTabTapped(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.black : const Color(0xFFF4F2EB),
        body: Stack(
          children: [
            // Tab Pages Container
            Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _selectedBottomIndex,
                    children: [
                      MapPage(
                        occurrences: _occurrences,
                        pontosRecolha: _showPontosRecolha ? _pontosRecolha : [],
                        isOnline: _isOnline,
                        onMapCreated: (mapbox.MapboxMap mapboxMap) => _mapboxMap = mapboxMap,
                        currentScale: _currentScale,
                        userLocation: _userLocation,
                        isResolvingGps: _isResolvingGps,
                        onScaleChanged: (scale) {
                          setState(() {
                            _currentScale = scale;
                          });
                        },
                        onLocationPressed: _onLocationPressed,
                        onReport: _onDenunciarPressed,
                        onOccurrenceSelected: (occ) =>
                            _animateMapTo(occ.position, 16.0),
                        showPontosRecolha: _showPontosRecolha,
                        onShowPontosRecolhaToggled: (val) {
                          setState(() {
                            _showPontosRecolha = val;
                          });
                        },
                      ),

                      // Tab 2: AI Assistant View
                      const ChatIAScreen(),

                      // Tab 3: Profile View
                      const ProfilePage(),
                    ],
                  ),
                ),
              ],
            ),

            // Custom Floating Glassmorphic App Bar
            if (_selectedBottomIndex == 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TxenezaAppBar(
                  isOnline: _isOnline,
                  onConnectivityTap: _toggleConnectivityManually,
                  unreadCount: _unreadCount,
                  onBellTap: _onBellTap,
                ),
              ),

            // Discrete Floating Offline / Sync Warning Banner
            if ((!_isOnline || _pendingCount > 0) && _selectedBottomIndex == 0)
              Positioned(
                top: MediaQuery.of(context).padding.top + 72.0,
                left: 12,
                right: 12,
                child: OfflineStatusBanner(
                  isOnline: _isOnline,
                  pendingCount: _pendingCount,
                  onSyncTap: () => SyncQueueSheet.show(
                    context,
                    isOnline: _isOnline,
                    onQueueUpdated: _flushQueue,
                  ),
                ),
              ),
          ],
        ),

        // Custom Floating Bottom Navigation Bar
        bottomNavigationBar: FloatingBottomNavigationBar(
          selectedIndex: _selectedBottomIndex,
          onDestinationSelected: _onTabTapped,
          destinations: const [
            FloatingNavigationDestination(
              icon: LucideIcons.map,
              label: 'Início',
            ),
            FloatingNavigationDestination(
              icon: LucideIcons.sparkles,
              label: 'Assistente IA',
            ),
            FloatingNavigationDestination(
              icon: LucideIcons.user,
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// Locate self GPS location button with spinning effect when resolving
class FloatingLocationButton extends StatefulWidget {
  final bool isResolving;
  final VoidCallback onPressed;

  const FloatingLocationButton({
    super.key,
    required this.isResolving,
    required this.onPressed,
  });

  @override
  State<FloatingLocationButton> createState() => _FloatingLocationButtonState();
}

class _FloatingLocationButtonState extends State<FloatingLocationButton> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isResolving) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FloatingLocationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isResolving != oldWidget.isResolving) {
      if (widget.isResolving) {
        _animController.repeat();
      } else {
        _animController.stop();
        _animController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE8E5DD),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onPressed,
          child: Center(
            child: widget.isResolving
                ? RotationTransition(
                    turns: _animController,
                    child: const Icon(
                      LucideIcons.locate,
                      color: AppColors.forestGreen,
                      size: 20,
                    ),
                  )
                : Icon(
                    LucideIcons.locate,
                    color: isDark ? Colors.white70 : const Color(0xFF424242),
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}

