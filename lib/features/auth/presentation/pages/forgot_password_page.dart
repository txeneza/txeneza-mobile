import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/colors/light_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../common/data/supabase_error_translator.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _remoteDataSource = AuthRemoteDataSource();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, introduza o seu e-mail.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Por favor, introduza um e-mail válido.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _remoteDataSource.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final msg = SupabaseErrorTranslator.translate(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho Curvo Parabólico com botão de voltar
                Stack(
                  children: [
                    const AuthHeaderWidget(),
                    Positioned(
                      top: 48,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                        child: IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSpacing.verticalSpaceMD,
                      Text(
                        'Recuperar Senha',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: isDark ? AppColors.white : AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalSpaceXS,
                      Text(
                        _emailSent
                            ? 'Instruções enviadas para o seu e-mail com sucesso!'
                            : 'Introduza o e-mail associado à sua conta para receber as instruções de recuperação.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.grey300 : AppColors.grey800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalSpaceXL,

                      if (!_emailSent) ...[
                        // Form Card
                        Card(
                          color: isDark ? DarkColors.surface : LightColors.surface.withValues(alpha: 0.15),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _emailController,
                                  labelText: 'E-mail de Registo',
                                  hintText: 'exemplo@email.com',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  prefixIcon: LucideIcons.mail,
                                  validator: _validateEmail,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.verticalSpaceLG,

                        // Botão Enviar
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return isDark ? AppColors.grey800 : AppColors.grey300;
                              }
                              return isDark ? DarkColors.primary : LightColors.primary;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return AppColors.grey600;
                              }
                              return isDark ? DarkColors.onPrimary : LightColors.onPrimary;
                            }),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Enviar Instruções'),
                        ),
                      ] else ...[
                        // Success State Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.forestGreen.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.mailCheck,
                                  color: AppColors.white,
                                  size: 32,
                                ),
                              ),
                              AppSpacing.verticalSpaceMD,
                              Text(
                                'Verifique a sua caixa de entrada',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.white : AppColors.forestGreen,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.verticalSpaceXS,
                              Text(
                                'Enviámos uma hiperligação de recuperação para:\n${_emailController.text.trim()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.grey800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.verticalSpaceXL,

                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.forestGreen),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Voltar ao Login',
                            style: TextStyle(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      AppSpacing.verticalSpaceXL,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
