import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/constants/auth_strings.dart';
import '../../../../core/constants/beira_neighborhoods.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/colors/light_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../data/datasources/profile_completion_service.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/custom_text_field.dart';

/// Ecrã obrigatório após o login quando o perfil não tem bairro definido.
/// Acontece sobretudo com contas criadas via Google, que não passam bairro.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _service = ProfileCompletionService();

  String? _selectedNeighborhood;
  bool _isSaving = false;
  bool _isAutovalidating = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    // Telefone é opcional aqui: o objectivo do ecrã é o bairro.
    if (value == null || value.trim().isEmpty) return null;
    final cleanPhone = value.replaceAll(' ', '');
    final phoneRegex = RegExp(r'^(82|83|84|85|86|87)\d{7}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return AuthStrings.phoneInvalid;
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _isAutovalidating = true);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedNeighborhood == null) {
      _showError(AuthStrings.neighborhoodRequired);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await _service.completeProfile(
        bairro: _selectedNeighborhood!,
        telefone: _phoneController.text.replaceAll(' ', ''),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('Não foi possível guardar. Verifique a ligação e tente novamente.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Geist')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sem botão de voltar: o ecrã é obrigatório para continuar.
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              autovalidateMode: _isAutovalidating
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeaderWidget(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSpacing.verticalSpaceLG,
                        Text(
                          'Quase lá',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color:
                                isDark ? AppColors.white : AppColors.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.verticalSpaceXS,
                        Text(
                          'Indique o seu bairro para podermos localizar e '
                          'encaminhar as suas denúncias na Beira.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.grey300 : AppColors.grey800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.verticalSpaceXL,
                        Card(
                          color: isDark
                              ? DarkColors.surface
                              : LightColors.surface.withValues(alpha: 0.15),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              children: [
                                _buildNeighborhoodDropdown(isDark, theme),
                                AppSpacing.verticalSpaceMD,
                                CustomTextField(
                                  controller: _phoneController,
                                  labelText:
                                      '${AuthStrings.phoneLabel} (opcional)',
                                  hintText: AuthStrings.phoneHint,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  focusNode: _phoneFocusNode,
                                  prefixIcon: LucideIcons.phone,
                                  validator: _validatePhone,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.verticalSpaceLG,
                        ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return isDark
                                    ? AppColors.grey800
                                    : AppColors.grey300;
                              }
                              return isDark
                                  ? DarkColors.primary
                                  : LightColors.primary;
                            }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return AppColors.grey600;
                              }
                              return isDark
                                  ? DarkColors.onPrimary
                                  : LightColors.onPrimary;
                            }),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Continuar'),
                        ),
                        AppSpacing.verticalSpaceLG,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborhoodDropdown(bool isDark, ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedNeighborhood,
      isExpanded: true,
      dropdownColor: isDark ? DarkColors.surface : AppColors.white,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'Geist',
        color: isDark ? AppColors.white : AppColors.grey900,
      ),
      hint: Text(
        AuthStrings.neighborhoodHint,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
      ),
      decoration: InputDecoration(
        labelText: AuthStrings.neighborhoodLabel,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.grey300 : AppColors.grey600,
        ),
        prefixIcon: Icon(
          LucideIcons.mapPin,
          color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
          size: 20,
        ),
        errorMaxLines: 3,
      ),
      items: BeiraNeighborhoods.list
          .map((b) => DropdownMenuItem<String>(value: b, child: Text(b)))
          .toList(),
      onChanged: (value) => setState(() => _selectedNeighborhood = value),
      validator: (value) =>
          (value == null || value.isEmpty) ? AuthStrings.neighborhoodRequired : null,
    );
  }
}
