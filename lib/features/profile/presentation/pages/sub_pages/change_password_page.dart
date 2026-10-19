import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/errors/supabase_error_translator.dart';
import '../../../../../core/services/auth_provider_resolver.dart';
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
  bool _isGoogleOnly = false;

  @override
  void initState() {
    super.initState();
    _isGoogleOnly = AuthProviderResolver.isGoogleOnly();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Nenhuma sessão ativa encontrada. Inicie sessão novamente.');
      }

      // Se a conta já tiver palavra-passe prévia, valida a atual antes de prosseguir
      if (!_isGoogleOnly) {
        final email = currentUser.email;
        final currentPass = _currentPasswordController.text.trim();
        if (email != null && currentPass.isNotEmpty) {
          await client.auth.signInWithPassword(
            email: email,
            password: currentPass,
          );
        }
      }

      // Atualiza ou define a palavra-passe diretamente no Supabase Auth
      await client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text.trim(),
        ),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isGoogleOnly
                ? 'Palavra-passe definida com sucesso. Pode agora iniciar sessão com a sua palavra-passe ou com a Google.'
                : 'Palavra-passe alterada com sucesso.',
            style: const TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final mensagemErro = SupabaseErrorTranslator.translate(e);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensagemErro,
            style: const TextStyle(fontFamily: 'Geist'),
          ),
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

    final String pageTitle = _isGoogleOnly ? 'Definir Palavra-passe' : 'Alterar Palavra-passe';
    final String pageDescription = _isGoogleOnly
        ? 'A sua conta foi criada através da Google e não possui palavra-passe associada. Ao definir uma palavra-passe, poderá aceder à plataforma tanto através da Google como utilizando diretamente o seu endereço de e-mail.'
        : 'Defina uma nova palavra-passe forte para proteger a sua conta Txeneza.';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 18),
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
                pageDescription,
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
                      // Se a conta for exclusivamente Google, não exige palavra-passe atual
                      if (!_isGoogleOnly) ...[
                        CustomTextField(
                          controller: _currentPasswordController,
                          labelText: 'Palavra-passe Atual',
                          hintText: 'Introduza a sua palavra-passe atual',
                          prefixIcon: LucideIcons.lock,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Introduza a sua palavra-passe atual.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomTextField(
                        controller: _newPasswordController,
                        labelText: _isGoogleOnly ? 'Nova Palavra-passe' : 'Nova Palavra-passe',
                        hintText: 'No mínimo 6 carateres',
                        prefixIcon: LucideIcons.keyRound,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'A palavra-passe deve conter pelo menos 6 carateres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirmar Palavra-passe',
                        hintText: 'Repita a nova palavra-passe',
                        prefixIcon: LucideIcons.checkCircle2,
                        isPassword: true,
                        validator: (value) {
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
                    : Text(
                        _isGoogleOnly ? 'Definir Palavra-passe' : 'Guardar Alterações',
                        style: const TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
