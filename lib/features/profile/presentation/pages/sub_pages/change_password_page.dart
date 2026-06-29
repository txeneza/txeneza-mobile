import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/spacing/app_spacing.dart';
import '../../../../auth/presentation/widgets/custom_text_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Simular alteração
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Palavra-passe alterada com sucesso! (Demonstração)',
                style: TextStyle(fontFamily: 'Geist'),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Alterar Palavra-passe',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Defina uma nova palavra-passe forte para proteger a sua conta Txeneza.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: isDark ? AppColors.grey300 : AppColors.grey600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: isDark ? const Color(0xFF1E2F2C) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _currentPasswordController,
                        labelText: 'Palavra-passe Atual',
                        hintText: 'Digite a sua palavra-passe atual',
                        isPassword: true,
                        prefixIcon: LucideIcons.lock,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, introduza a palavra-passe atual.';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.verticalSpaceMD,
                      CustomTextField(
                        controller: _newPasswordController,
                        labelText: 'Nova Palavra-passe',
                        hintText: 'Digite a nova palavra-passe',
                        isPassword: true,
                        prefixIcon: LucideIcons.lock,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, introduza a nova palavra-passe.';
                          }
                          if (value.length < 8) {
                            return 'A palavra-passe deve ter pelo menos 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.verticalSpaceMD,
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirmar Nova Palavra-passe',
                        hintText: 'Confirme a nova palavra-passe',
                        isPassword: true,
                        prefixIcon: LucideIcons.lock,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme a nova palavra-passe.';
                          }
                          if (value != _newPasswordController.text) {
                            return 'As palavras-passe não coincidem.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return isDark ? AppColors.grey800 : AppColors.grey300;
                    }
                    return AppColors.forestGreen;
                  }),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvar Palavra-passe',
                        style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
