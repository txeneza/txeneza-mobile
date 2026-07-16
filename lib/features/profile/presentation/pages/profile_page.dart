import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';
import '../widgets/ai_chat_bottom_sheet.dart';
import '../widgets/profile_gamification_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_privacy_section.dart';
import '../widgets/profile_quick_access.dart';
import '../widgets/profile_settings_section.dart';
import '../widgets/profile_stats_grid.dart';
import '../widgets/profile_support_section.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(repository: ProfileRepositoryImpl());
    _controller.loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showLogoutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? DarkColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Terminar Sessão',
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.forestGreen,
            ),
          ),
          content: Text(
            'Tem a certeza que deseja sair da sua conta?',
            style: TextStyle(
              fontFamily: 'Geist',
              color: isDark ? Colors.white70 : AppColors.grey800,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Sair',
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? DarkColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Eliminar Conta',
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          content: Text(
            'Aviso: Esta ação é irreversível e apagará permanentemente todos os seus dados. Deseja prosseguir?',
            style: TextStyle(
              fontFamily: 'Geist',
              color: isDark ? Colors.white70 : AppColors.grey800,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Funcionalidade disponível quando o backend estiver integrado.',
                      style: TextStyle(fontFamily: 'Geist'),
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openAIChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIChatBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        if (state is ProfileLoading || state is ProfileInitial) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.grey900 : const Color(0xFFF4F2EB),
            body: Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.grey900 : const Color(0xFFF4F2EB),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 40,
                      color: isDark ? Colors.white38 : AppColors.grey600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.grey800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => _controller.loadProfile(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Tentar Novamente',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Obtém o perfil carregado (ou em atualização)
        final profile = (state is ProfileLoaded)
            ? state.profile
            : (state as ProfileUpdating).currentProfile;
        final isUpdating = state is ProfileUpdating;

        return Scaffold(
          backgroundColor: isDark ? AppColors.grey900 : const Color(0xFFF4F2EB),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor: isDark ? DarkColors.surface : AppColors.forestGreen,
            foregroundColor: isDark ? AppColors.sageGreen : Colors.white,
            elevation: 2,
            tooltip: 'Assistente IA Xeni',
            onPressed: _openAIChat,
            child: const Icon(LucideIcons.sparkles, size: 18),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Enterprise
                ProfileHeader(
                  fullName: profile.fullName,
                  isVerified: profile.isVerified,
                ),

                const SizedBox(height: 20),

                // 2. Informações Pessoais
                ProfileInfoCard(
                  profile: profile,
                  isUpdating: isUpdating,
                  onSave: (fullName, phoneNumber, neighborhood) async {
                    final success = await _controller.updateProfile(
                      fullName: fullName,
                      phoneNumber: phoneNumber,
                      neighborhood: neighborhood,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Perfil atualizado com sucesso.'
                                : 'Erro ao atualizar dados. Tente novamente.',
                            style: const TextStyle(fontFamily: 'Geist'),
                          ),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),

                // 3. Estatísticas
                ProfileStatsGrid(
                  reportsSubmitted: profile.reportsSubmitted,
                  reportsResolved: profile.reportsResolved,
                  reportsPending: profile.reportsPending,
                ),

                const SizedBox(height: 16),

                // 4. Gamificação
                ProfileGamificationCard(
                  points: profile.points,
                  level: profile.level,
                  badges: profile.badges,
                ),

                const SizedBox(height: 16),

                // 5. Histórico (Quick Access)
                const ProfileQuickAccess(),

                const SizedBox(height: 16),

                // 6. Configurações
                ProfileSettingsSection(
                  pushNotifications: _controller.pushNotifications,
                  emailNotifications: _controller.emailNotifications,
                  offlineSync: _controller.offlineSync,
                  language: _controller.language,
                  onPushChanged: _controller.setPushNotifications,
                  onEmailChanged: _controller.setEmailNotifications,
                  onOfflineChanged: _controller.setOfflineSync,
                  onLanguageChanged: _controller.setLanguage,
                ),

                const SizedBox(height: 16),

                // 7. Privacidade & Segurança
                ProfilePrivacySection(
                  locationPermission: _controller.locationPermission,
                  cameraPermission: _controller.cameraPermission,
                  onLocationPermissionChanged: _controller.setLocationPermission,
                  onCameraPermissionChanged: _controller.setCameraPermission,
                ),

                const SizedBox(height: 16),

                // 8. Suporte
                const ProfileSupportSection(),

                const SizedBox(height: 16),

                // 9. Sessão — Botões outline enterprise
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    children: [
                      // Terminar Sessão
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(isDark),
                          icon: Icon(
                            LucideIcons.logOut,
                            size: 16,
                            color: isDark ? Colors.white54 : AppColors.grey800,
                          ),
                          label: Text(
                            'Terminar Sessão',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : AppColors.grey800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Eliminar Conta
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _showDeleteAccountDialog(isDark),
                          icon: Icon(
                            LucideIcons.trash2,
                            size: 14,
                            color: AppColors.error.withValues(alpha: 0.7),
                          ),
                          label: Text(
                            'Eliminar Conta',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.error.withValues(alpha: 0.7),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        );
      },
    );
  }
}
