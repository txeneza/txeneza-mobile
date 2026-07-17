import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/constants/auth_strings.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/colors/light_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/profile_completion_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/google_sign_in_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _selectedNeighborhood;

  late final AuthRemoteDataSource _remoteDataSource;
  late final AuthRepositoryImpl _repository;
  late final AuthController _controller;

  bool _isAutovalidating = false;
  bool _usedGoogleSignIn = false;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AuthRemoteDataSource();
    _repository = AuthRepositoryImpl(remoteDataSource: _remoteDataSource);
    _controller = AuthController(repository: _repository);
    
    _controller.addListener(_onStateChanged);
    
    // Fetch neighborhoods asynchronously (future supabase compatibility)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchNeighborhoods();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;

    final state = _controller.state;
    if (state is AuthSuccess && _usedGoogleSignIn) {
      // Login com Google já autentica de facto: segue directo para a home.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AuthStrings.loginSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _goToNextScreen();
    } else if (state is AuthSuccess || state is AuthSignUpPendingConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state is AuthSignUpPendingConfirmation
                ? AuthStrings.signUpPendingConfirmation
                : AuthStrings.signUpSuccess,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navegar de volta ao login após cadastro de sucesso
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _goToNextScreen() async {
    final needsCompletion = await ProfileCompletionService().needsCompletion();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      needsCompletion ? AppRoutes.completeProfile : AppRoutes.home,
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AuthStrings.fullNameRequired;
    }
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return AuthStrings.fullNameTwoWords;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AuthStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AuthStrings.emailInvalid;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AuthStrings.phoneRequired;
    }
    // Remove espaços para validação
    final cleanPhone = value.replaceAll(' ', '');
    final phoneRegex = RegExp(r'^(82|83|84|85|86|87)\d{7}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return AuthStrings.phoneInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AuthStrings.passwordRequired;
    }
    if (value.length < 8) {
      return AuthStrings.passwordTooShort;
    }
    final hasUppercase = RegExp(r'[A-Z]');
    final hasLowercase = RegExp(r'[a-z]');
    final hasDigit = RegExp(r'[0-9]');
    if (!hasUppercase.hasMatch(value) || !hasLowercase.hasMatch(value) || !hasDigit.hasMatch(value)) {
      return AuthStrings.passwordStrength;
    }
    return null;
  }

  void _submit() {
    setState(() {
      _isAutovalidating = true;
    });

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedNeighborhood == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AuthStrings.neighborhoodRequired),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      FocusScope.of(context).unfocus();
      _usedGoogleSignIn = false;
      _controller.signUp(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        neighborhood: _selectedNeighborhood!,
      );
    }
  }

  void _submitGoogle() {
    _usedGoogleSignIn = true;
    _controller.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                autovalidateMode: _isAutovalidating
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho Curvo Parabólico com botão de voltar
                    const AuthHeaderWidget(showBackButton: true),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSpacing.verticalSpaceLG,
                          Text(
                            AuthStrings.signUpTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: isDark ? AppColors.white : AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.verticalSpaceXS,

                          Text(
                            AuthStrings.signUpSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.grey300 : AppColors.grey800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.verticalSpaceXL,

                          // Inputs Card
                          Card(
                            color: isDark ? DarkColors.surface : LightColors.surface.withValues(alpha: 0.15),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  CustomTextField(
                                    controller: _nameController,
                                    labelText: AuthStrings.fullNameLabel,
                                    hintText: AuthStrings.fullNameHint,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    focusNode: _nameFocusNode,
                                    prefixIcon: LucideIcons.user,
                                    validator: _validateName,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_emailFocusNode);
                                    },
                                  ),
                                  AppSpacing.verticalSpaceMD,
                                  CustomTextField(
                                    controller: _emailController,
                                    labelText: AuthStrings.emailLabel,
                                    hintText: AuthStrings.emailHint,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    focusNode: _emailFocusNode,
                                    prefixIcon: LucideIcons.mail,
                                    validator: _validateEmail,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_phoneFocusNode);
                                    },
                                  ),
                                  AppSpacing.verticalSpaceMD,
                                  CustomTextField(
                                    controller: _phoneController,
                                    labelText: AuthStrings.phoneLabel,
                                    hintText: AuthStrings.phoneHint,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    focusNode: _phoneFocusNode,
                                    prefixIcon: LucideIcons.phone,
                                    validator: _validatePhone,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                                    },
                                  ),
                                  AppSpacing.verticalSpaceMD,
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: AuthStrings.passwordLabel,
                                    hintText: AuthStrings.passwordHint,
                                    isPassword: true,
                                    textInputAction: TextInputAction.next,
                                    focusNode: _passwordFocusNode,
                                    prefixIcon: LucideIcons.lock,
                                    validator: _validatePassword,
                                  ),
                                  AppSpacing.verticalSpaceMD,

                                  // Neighborhood Dropdown
                                  _buildNeighborhoodDropdown(isDark, theme),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.verticalSpaceLG,

                          // Submit Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _submit,
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
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text(AuthStrings.signUpButton),
                          ),
                          AppSpacing.verticalSpaceLG,

                          // Login com Google
                          GoogleSignInButton(
                            isDark: isDark,
                            onPressed: isLoading ? null : _submitGoogle,
                          ),
                          AppSpacing.verticalSpaceLG,

                          // Navigate back to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AuthStrings.hasAccount,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.grey300 : AppColors.grey800,
                                ),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).pop();
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AuthStrings.loginNow,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? DarkColors.primary : LightColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.verticalSpaceLG,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNeighborhoodDropdown(bool isDark, ThemeData theme) {
    if (_controller.isLoadingNeighborhoods) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.forestGreen,
              ),
            ),
            AppSpacing.horizontalSpaceSM,
            Text(
              'A carregar bairros...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      );
    }

    if (_controller.neighborhoodsError != null) {
      return TextButton.icon(
        onPressed: () => _controller.fetchNeighborhoods(),
        icon: const Icon(LucideIcons.refreshCw, size: 16),
        label: const Text('Erro ao carregar bairros. Toque para recarregar.'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedNeighborhood,
      hint: Text(
        AuthStrings.neighborhoodHint,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.grey600,
        ),
      ),
      isExpanded: true,
      dropdownColor: isDark ? DarkColors.surface : AppColors.white,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? AppColors.white : AppColors.grey900,
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
      items: _controller.neighborhoods.map((bairro) {
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
          return AuthStrings.neighborhoodRequired;
        }
        return null;
      },
    );
  }
}
