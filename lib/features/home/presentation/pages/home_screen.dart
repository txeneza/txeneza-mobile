import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../../../../core/theme/colors/app_colors.dart';
import '../../../../shared/widgets/layout/app_bar.dart';
import '../../../map/domain/occurrence_model.dart';
import '../../../map/presentation/pages/map_page.dart';
import '../../../map/presentation/widgets/txeneza_map.dart' show MapMode;
import '../../../chatIA/presentation/pages/chat_ia_screen.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/floating_bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedBottomIndex = 0;
  MapMode _mapMode = MapMode.normal;

  // Connectivity state
  bool _isOnline = true;
  bool _isManualOverride = false;
  bool _isFirstConnectivityEvent = true;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Map state
  late final MapController _mapController;
  double _currentScale = 12.5;
  bool _isResolvingGps = false;
  final LatLng _userLocation = const LatLng(-19.8300, 34.8400); // Ponta Gêa, Beira

  // FAB animation state
  bool _isFabPressed = false;

  // Complete list of occurrences (Online)
  final List<Occurrence> _allOccurrences = const [
    Occurrence(
      id: '1',
      position: LatLng(-19.8380, 34.8380),
      status: OccurrenceStatus.pending,
      title: 'Acúmulo de Lixo - Ponta Gêa',
      description: 'Resíduos domésticos descartados na berma da estrada.',
    ),
    Occurrence(
      id: '2',
      position: LatLng(-19.8350, 34.8410),
      status: OccurrenceStatus.critical,
      title: 'Lixeira Irregular - Centro',
      description: 'Grande quantidade de plásticos acumulados obstruindo a calçada.',
    ),
    Occurrence(
      id: '3',
      position: LatLng(-19.8100, 34.8150),
      status: OccurrenceStatus.critical,
      title: 'Resíduos de Mercado - Munhava',
      description: 'Restos orgânicos atraindo pragas no mercado local.',
    ),
    Occurrence(
      id: '4',
      position: LatLng(-19.8150, 34.8100),
      status: OccurrenceStatus.pending,
      title: 'Foco de Lixo - Munhava',
      description: 'Entulho acumulado há mais de duas semanas.',
    ),
    Occurrence(
      id: '5',
      position: LatLng(-19.8080, 34.8200),
      status: OccurrenceStatus.resolved,
      title: 'Limpeza Efetuada - Munhava',
      description: 'Zona de lixeira eliminada e revitalizada.',
    ),
    Occurrence(
      id: '6',
      position: LatLng(-19.8250, 34.8700),
      status: OccurrenceStatus.pending,
      title: 'Lixo na Praia - Macuti',
      description: 'Garrafas plásticas e redes de pesca abandonadas na areia.',
    ),
    Occurrence(
      id: '7',
      position: LatLng(-19.8280, 34.8750),
      status: OccurrenceStatus.resolved,
      title: 'Ação de Limpeza - Macuti',
      description: 'Voluntários recolheram detritos na orla marítima.',
    ),
    Occurrence(
      id: '8',
      position: LatLng(-19.8200, 34.8680),
      status: OccurrenceStatus.pending,
      title: 'Lixeira de Estrada - Macuti',
      description: 'Sacos de lixo rasgados espalhados pelo vento.',
    ),
    Occurrence(
      id: '9',
      position: LatLng(-19.8200, 34.8450),
      status: OccurrenceStatus.resolved,
      title: 'Vala Desobstruída - Esturro',
      description: 'Retirada de resíduos sólidos que impediam o fluxo de água.',
    ),
    Occurrence(
      id: '10',
      position: LatLng(-19.8180, 34.8500),
      status: OccurrenceStatus.resolved,
      title: 'Contentor Esvaziado - Chota',
      description: 'Limpeza de contentor público saturado.',
    ),
  ];

  // Cached occurrences list (Offline)
  List<Occurrence> get _occurrences => _isOnline 
      ? _allOccurrences 
      : _allOccurrences.where((o) => o.id == '1' || o.id == '2' || o.id == '5' || o.id == '7' || o.id == '9' || o.id == '10').toList();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!_isManualOverride) {
        _updateConnectionStatus(results);
      }
    });
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
    _mapController.dispose();
    super.dispose();
  }

  // Smooth map centering animation
  void _animateMapTo(LatLng target, double targetZoom) {
    try {
      final double startZoom = _mapController.camera.zoom;
      final LatLng startCenter = _mapController.camera.center;

      final latTween = Tween<double>(begin: startCenter.latitude, end: target.latitude);
      final lngTween = Tween<double>(begin: startCenter.longitude, end: target.longitude);
      final zoomTween = Tween<double>(begin: startZoom, end: targetZoom);

      final AnimationController controller = AnimationController(
        duration: const Duration(milliseconds: 900),
        vsync: this,
      );

      final Animation<double> animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutCubic,
      );

      controller.addListener(() {
        if (!mounted) return;
        try {
          _mapController.move(
            LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
            zoomTween.evaluate(animation),
          );
          setState(() {
            _currentScale = zoomTween.evaluate(animation);
          });
        } catch (e) {
          debugPrint('Failed to move map: $e');
          controller.stop();
        }
      });

      controller.forward().then((_) {
        if (mounted) {
          controller.dispose();
        }
      });
    } catch (e) {
      debugPrint('MapController is not ready yet: $e');
    }
  }

  void _onLocationPressed() {
    if (_isResolvingGps) return;

    setState(() {
      _isResolvingGps = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isResolvingGps = false;
        });
        _animateMapTo(_userLocation, 15.0);
      }
    });
  }

  void _onDenunciarPressed() {
    if (_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Denúncia enviada com sucesso para o servidor!',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você está offline. A denúncia foi guardada no dispositivo e será sincronizada assim que a internet retornar.',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: Color(0xFFFB8C00),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Handle bottom navigation updates
  void _onTabTapped(int index) {
    setState(() {
      _selectedBottomIndex = index;
      if (index == 0) {
        _mapMode = MapMode.normal;
      } else if (index == 1) {
        _mapMode = MapMode.heatmap;
      }
    });
  }

  // Handle floating toggle changes
  void _onMapModeToggled(MapMode mode) {
    setState(() {
      _mapMode = mode;
      if (mode == MapMode.normal) {
        _selectedBottomIndex = 0;
      } else if (mode == MapMode.heatmap) {
        _selectedBottomIndex = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show FAB only on map-related tabs (Início & Mapa de Calor)
    final showFAB = _selectedBottomIndex == 0 || _selectedBottomIndex == 1;

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
                    index: (_selectedBottomIndex == 0 || _selectedBottomIndex == 1) ? 0 : (_selectedBottomIndex - 1),
                    children: [
                      MapPage(
                        mapMode: _mapMode,
                        occurrences: _occurrences,
                        isOnline: _isOnline,
                        mapController: _mapController,
                        currentScale: _currentScale,
                        userLocation: _userLocation,
                        isResolvingGps: _isResolvingGps,
                        onScaleChanged: (scale) {
                          setState(() {
                            _currentScale = scale;
                          });
                        },
                        onMapModeToggled: _onMapModeToggled,
                        onLocationPressed: _onLocationPressed,
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
            if (_selectedBottomIndex != 2 && _selectedBottomIndex != 3)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TxenezaAppBar(
                  isOnline: _isOnline,
                  onConnectivityTap: _toggleConnectivityManually,
                ),
              ),

            // Discrete Floating Offline Warning Banner
            if (!_isOnline && _selectedBottomIndex != 2 && _selectedBottomIndex != 3)
              Positioned(
                top: MediaQuery.of(context).padding.top + 76.0,
                left: 16,
                right: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const ClipRect(
                    child: Align(
                      alignment: Alignment.center,
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.wifiOff,
                            color: AppColors.forestGreen,
                            size: 14,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Modo Offline. Pontos salvos na última sincronização.',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              color: AppColors.forestGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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

        // Primary Action FAB Button (Camera + Denunciar)
        floatingActionButton: showFAB
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _isFabPressed = true;
                    });
                  },
                  onTapUp: (_) {
                    setState(() {
                      _isFabPressed = false;
                    });
                    _onDenunciarPressed();
                  },
                  onTapCancel: () {
                    setState(() {
                      _isFabPressed = false;
                    });
                  },
                  child: AnimatedScale(
                    scale: _isFabPressed ? 0.96 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 154,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _isFabPressed 
                            ? (Color.lerp(AppColors.forestGreen, Colors.black, 0.15) ?? AppColors.forestGreen)
                            : AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forestGreen.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Denunciar',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,

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
              icon: LucideIcons.flame,
              label: 'Mapa Calor',
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
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
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
                : const Icon(
                    LucideIcons.locate,
                    color: Color(0xFF424242),
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
