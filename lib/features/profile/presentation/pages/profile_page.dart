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
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_quick_access.dart';
import '../widgets/profile_stats_grid.dart';
import '../widgets/profile_support_section.dart';
import '../widgets/profile_settings_section.dart';

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

  Future<void> _confirmLogout(bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        isDark: isDark,
        title: 'Terminar Sessão',
        message: 'Tem a certeza que deseja sair da sua conta?',
        confirmLabel: 'Sair',
        confirmColor: AppColors.error,
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Erro ao fazer sign out: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount(bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        isDark: isDark,
        title: 'Eliminar Conta',
        message: 'Esta ação é irreversível. A sua conta e todas as suas '
            'denúncias serão apagadas permanentemente. Deseja continuar?',
        confirmLabel: 'Eliminar definitivamente',
        confirmColor: AppColors.error,
        titleColor: AppColors.error,
      ),
    );
    if (confirm != true || !mounted) return;

    _showBlockingLoader();
    try {
      await _controller.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pop(); // fecha o loader
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // fecha o loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível eliminar a conta. Tente novamente.',
            style: const TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showBlockingLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.forestGreen),
      ),
    );
  }

  Widget _confirmDialog(
    BuildContext ctx, {
    required bool isDark,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    Color? titleColor,
  }) {
    return AlertDialog(
      backgroundColor: isDark ? DarkColors.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Geist',
          fontWeight: FontWeight.w700,
          color: titleColor ?? (isDark ? Colors.white : AppColors.forestGreen),
        ),
      ),
      content: Text(
        message,
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
          child: Text(
            confirmLabel,
            style: TextStyle(
              fontFamily: 'Geist',
              color: confirmColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
          return _scaffold(
            isDark,
            Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (state is ProfileError) {
          return _scaffold(isDark, _errorView(isDark, state.message));
        }

        final profile = (state is ProfileLoaded)
            ? state.profile
            : (state as ProfileUpdating).currentProfile;
        final stats = (state is ProfileLoaded)
            ? state.stats
            : (state as ProfileUpdating).stats;
        final isUpdating = state is ProfileUpdating;

        return _scaffold(
          isDark,
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  fullName: profile.fullName,
                  isVerified: profile.isVerified,
                ),
                const SizedBox(height: 20),
                ProfileInfoCard(
                  profile: profile,
                  isUpdating: isUpdating,
                  onSave: (fullName, phoneNumber, neighborhood) async {
                    final success = await _controller.updateProfile(
                      fullName: fullName,
                      phoneNumber: phoneNumber,
                      neighborhood: neighborhood,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Perfil atualizado com sucesso.'
                              : 'Erro ao atualizar dados. Tente novamente.',
                          style: const TextStyle(fontFamily: 'Geist'),
                        ),
                        backgroundColor:
                            success ? AppColors.success : AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ProfileStatsGrid(
                  reportsSubmitted: stats.submitted,
                  reportsResolved: stats.resolved,
                  reportsPending: stats.pending,
                ),
                const SizedBox(height: 16),
                const ProfileQuickAccess(),
                const SizedBox(height: 16),
                const ProfileSettingsSection(),
                const SizedBox(height: 16),
                const ProfileSupportSection(),
                const SizedBox(height: 16),
                _sessionButtons(isDark),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Scaffold _scaffold(bool isDark, Widget body) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.grey900 : const Color(0xFFF4F2EB),
      body: body,
    );
  }

  Widget _errorView(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.triangleAlert,
                size: 40, color: isDark ? Colors.white38 : AppColors.grey600),
            const SizedBox(height: 16),
            Text(
              message,
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
                    color:
                        isDark ? AppColors.sageGreen : AppColors.forestGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
  }

  Widget _sessionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(isDark),
              icon: Icon(LucideIcons.logOut,
                  size: 16,
                  color: isDark ? Colors.white54 : AppColors.grey800),
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.grey300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _confirmDeleteAccount(isDark),
              icon: Icon(LucideIcons.trash2,
                  size: 14, color: AppColors.error.withValues(alpha: 0.8)),
              label: Text(
                'Eliminar Conta',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error.withValues(alpha: 0.8),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
