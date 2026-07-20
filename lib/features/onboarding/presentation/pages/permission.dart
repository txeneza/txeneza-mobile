import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'web_permission_helper_stub.dart'
    if (dart.library.html) 'web_permission_helper_web.dart' as helper;

import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/spacing/app_radius.dart';
import '../../../../core/theme/icons/app_icons.dart';
import '../../../../core/config/routes/app_routes.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _cameraDeniedOnce = false;
  bool _locationDeniedOnce = false;
  bool _notificationDeniedOnce = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    if (kIsWeb) {
      // In Web, we usually check permissions on request, so default to false
      return;
    }

    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.locationWhenInUse.status;
    final notificationStatus = await Permission.notification.status;

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
      _notificationGranted = notificationStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    if (kIsWeb) {
      await _requestWebPermissions();
    } else {
      await _requestNativePermissions();
    }

    setState(() {
      _isRequesting = false;
    });

    // Câmara e Localização são essenciais para o funcionamento do app.
    // Notificação é pedida aqui também, mas não bloqueia o avanço se negada.
    if (_cameraGranted && _locationGranted) {
      await _completeFirstTimeConfig();
    } else {
      _showExplanationDialog();
    }
  }

  Future<void> _requestNativePermissions() async {
    // Request Camera
    if (!_cameraGranted) {
      final cameraStatus = await Permission.camera.request();
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
        if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
          _cameraDeniedOnce = true;
        }
      });
    }

    // Request Location
    if (!_locationGranted) {
      final locationStatus = await Permission.locationWhenInUse.request();
      setState(() {
        _locationGranted = locationStatus.isGranted;
        if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
          _locationDeniedOnce = true;
        }
      });
    }

    // Request Notifications
    if (!_notificationGranted) {
      final notificationStatus = await Permission.notification.request();
      setState(() {
        _notificationGranted = notificationStatus.isGranted;
        if (notificationStatus.isDenied ||
            notificationStatus.isPermanentlyDenied) {
          _notificationDeniedOnce = true;
        }
      });
    }
  }

  Future<void> _requestWebPermissions() async {
    final results = await helper.requestWebPermissions();
    setState(() {
      _cameraGranted = results[0];
      _locationGranted = results[1];
      if (!_cameraGranted) _cameraDeniedOnce = true;
      if (!_locationGranted) _locationDeniedOnce = true;
    });
  }

  Future<void> _completeFirstTimeConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  void _showExplanationDialog() {
    String explanation = '';
    if (!_cameraGranted && !_locationGranted) {
      explanation = 'A Câmara e a Localização são essenciais para que o Txeneza funcione. A câmara permite fotografar o lixo e a localização indica o local exato no mapa.';
    } else if (!_cameraGranted) {
      explanation = 'A Câmara é necessária para registrar imagens reais da ocorrência como prova visual do lixo acumulado.';
    } else {
      explanation = 'A Localização é essencial para marcar o ponto exato da ocorrência no mapa, permitindo que a edilidade encontre e resolva o problema.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
          title: Row(
            children: const [
              Icon(LucideIcons.alertTriangle, color: Color(0xFFFB8C00)),
              SizedBox(width: 8),
              Text(
                'Permissões Necessárias',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
          content: Text(
            explanation,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: AppColors.grey800,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: AppColors.grey600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!kIsWeb)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mintGreen,
                  foregroundColor: AppColors.forestGreen,
                  minimumSize: const Size(100, 36),
                ),
                child: const Text('Configurações'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 36),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              
              // App Logo / Icon Header
              Row(
                children: [
                  SvgPicture.asset(
                    AppIcons.logo,
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Txeneza',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Precisamos da tua ajuda para funcionar.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para reportar focos de poluição de forma rápida e precisa, precisamos das seguintes permissões:',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: AppColors.grey800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Permission Block 1: Camera
              _buildPermissionBlock(
                icon: LucideIcons.camera,
                title: 'Câmara',
                explanation: 'Para fotografar os pontos de lixo.',
                isGranted: _cameraGranted,
                isDenied: _cameraDeniedOnce,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Permission Block 2: Location
              _buildPermissionBlock(
                icon: LucideIcons.mapPin,
                title: 'Localização',
                explanation: 'Para marcar no mapa onde está o lixo.',
                isGranted: _locationGranted,
                isDenied: _locationDeniedOnce,
                isDark: isDark,
              ),

              // Permission Block 3: Notifications (não disponível na web)
              if (!kIsWeb) ...[
                const SizedBox(height: 16),
                _buildPermissionBlock(
                  icon: LucideIcons.bell,
                  title: 'Notificações',
                  explanation: 'Para avisar quando o estado da tua denúncia mudar.',
                  isGranted: _notificationGranted,
                  isDenied: _notificationDeniedOnce,
                  isDark: isDark,
                ),
              ],

              const Spacer(flex: 2),

              // Action Footer Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                    elevation: 2,
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Aceitar e Entrar',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionBlock({
    required IconData icon,
    required String title,
    required String explanation,
    required bool isGranted,
    required bool isDenied,
    required bool isDark,
  }) {
    final statusColor = isGranted
        ? AppColors.success
        : (isDenied ? AppColors.error : AppColors.grey600);

    final statusIcon = isGranted
        ? LucideIcons.checkCircle
        : (isDenied ? LucideIcons.xCircle : LucideIcons.helpCircle);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : Colors.white,
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDenied ? AppColors.error.withValues(alpha: 0.3) : (isDark ? AppColors.grey800 : AppColors.grey200)),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.forestGreen.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? AppColors.success : AppColors.forestGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Info Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status icon
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}
