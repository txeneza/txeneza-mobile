import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  bool _isEditing = false;

  String? _neighborhoodOrNull(String? bairro) =>
      BeiraNeighborhoods.list.contains(bairro) ? bairro : null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _selectedNeighborhood = _neighborhoodOrNull(widget.profile.neighborhood);
  }

  @override
  void didUpdateWidget(covariant ProfileInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _nameController.text = widget.profile.fullName;
      _phoneController.text = widget.profile.phoneNumber;
      _selectedNeighborhood = _neighborhoodOrNull(widget.profile.neighborhood);
      setState(() {
        _isEditing = false;
      });
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

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      // Restaura valores originais da base de dados
      _nameController.text = widget.profile.fullName;
      _phoneController.text = widget.profile.phoneNumber;
      _selectedNeighborhood = _neighborhoodOrNull(widget.profile.neighborhood);
    });
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isEditing ? _buildEditForm(theme, isDark) : _buildViewMode(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildViewMode(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('view_mode'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            IconButton(
              icon: Icon(
                LucideIcons.pencil,
                size: 18,
                color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: LucideIcons.user,
          label: 'Nome Completo',
          value: widget.profile.fullName.isNotEmpty ? widget.profile.fullName : 'Não definido',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: LucideIcons.phone,
          label: 'Número de Celular',
          value: widget.profile.phoneNumber.isNotEmpty ? widget.profile.phoneNumber : 'Não definido',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: LucideIcons.mapPin,
          label: 'Bairro de Residência',
          value: widget.profile.neighborhood.isNotEmpty ? widget.profile.neighborhood : 'Não definido',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: LucideIcons.mail,
          label: 'E-mail principal',
          value: widget.profile.email.isNotEmpty ? widget.profile.email : 'Não definido',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildEditForm(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('edit_mode'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Editar Informações',
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
            initialValue: _selectedNeighborhood,
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

          // Email (Apenas Leitura em Edição)
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
          
          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isUpdating ? null : _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.grey300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.grey800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
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
                          'Salvar',
                          style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.forestGreen.withValues(alpha: 0.15)
                : AppColors.forestGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
