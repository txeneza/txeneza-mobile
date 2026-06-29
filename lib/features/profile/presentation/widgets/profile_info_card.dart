import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/beira_neighborhoods.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../data/models/profile_user_model.dart';

class ProfileInfoCard extends StatefulWidget {
  final ProfileUserModel profile;
  final bool isUpdating;
  final Function(String fullName, String phoneNumber, String neighborhood) onSave;

  const ProfileInfoCard({
    super.key,
    required this.profile,
    required this.isUpdating,
    required this.onSave,
  });

  @override
  State<ProfileInfoCard> createState() => _ProfileInfoCardState();
}

class _ProfileInfoCardState extends State<ProfileInfoCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _selectedNeighborhood;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _selectedNeighborhood = widget.profile.neighborhood;
  }

  @override
  void didUpdateWidget(covariant ProfileInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _nameController.text = widget.profile.fullName;
      _phoneController.text = widget.profile.phoneNumber;
      _selectedNeighborhood = widget.profile.neighborhood;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedNeighborhood == null) return;
      widget.onSave(_nameController.text, _phoneController.text, _selectedNeighborhood!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? DarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informações Pessoais',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 16),
              
              // Nome Completo
              CustomTextField(
                controller: _nameController,
                labelText: 'Nome Completo',
                hintText: 'Insira o seu nome completo',
                keyboardType: TextInputType.name,
                prefixIcon: LucideIcons.user,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduza o seu nome.';
                  }
                  final words = value.trim().split(RegExp(r'\s+'));
                  if (words.length < 2) {
                    return 'Introduza o seu nome completo (mínimo 2 nomes).';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalSpaceMD,
              
              // Número de Celular
              CustomTextField(
                controller: _phoneController,
                labelText: 'Número de Celular',
                hintText: 'Ex: 841234567',
                keyboardType: TextInputType.phone,
                prefixIcon: LucideIcons.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduza o seu número.';
                  }
                  final cleanPhone = value.replaceAll(' ', '');
                  final phoneRegex = RegExp(r'^(82|83|84|85|86|87)\d{7}$');
                  if (!phoneRegex.hasMatch(cleanPhone)) {
                    return 'Número de celular inválido (formato Moçambicano).';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalSpaceMD,

              // Bairro (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedNeighborhood,
                isExpanded: true,
                dropdownColor: isDark ? DarkColors.surface : AppColors.white,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Geist',
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
                decoration: InputDecoration(
                  labelText: 'Bairro',
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Geist',
                    color: isDark ? AppColors.grey300 : AppColors.grey600,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.mapPin,
                    color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                    size: 20,
                  ),
                ),
                items: BeiraNeighborhoods.list.map((bairro) {
                  return DropdownMenuItem<String>(
                    value: bairro,
                    child: Text(bairro),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedNeighborhood = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione um bairro.';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalSpaceMD,

              // Email (Apenas Leitura)
              TextFormField(
                initialValue: widget.profile.email,
                readOnly: true,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  color: isDark ? AppColors.grey300 : AppColors.grey600,
                ),
                decoration: InputDecoration(
                  labelText: 'E-mail (Apenas Leitura)',
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Geist',
                    color: isDark ? AppColors.grey300 : AppColors.grey600,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.mail,
                    color: AppColors.grey600,
                    size: 20,
                  ),
                  suffixIcon: const Tooltip(
                    message: 'Editável mediante futura reverificação por e-mail.',
                    child: Icon(
                      LucideIcons.info,
                      size: 16,
                      color: AppColors.grey600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Botão Salvar
              ElevatedButton(
                onPressed: widget.isUpdating ? null : _submit,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return isDark ? AppColors.grey800 : AppColors.grey300;
                    }
                    return AppColors.forestGreen;
                  }),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                child: widget.isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvar Alterações',
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
