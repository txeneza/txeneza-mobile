import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/constants/auth_strings.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/colors/light_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/google_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late final AuthRemoteDataSource _remoteDataSource;
  late final AuthRepositoryImpl _repository;
  late final AuthController _controller;

  bool _isAutovalidating = false;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AuthRemoteDataSource();
    _repository = AuthRepositoryImpl(remoteDataSource: _remoteDataSource);
    _controller = AuthController(repository: _repository);
    
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    
    final state = _controller.state;
    if (state is AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AuthStrings.loginSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AuthStrings.passwordRequired;
    }
    if (value.length < 8) {
      return AuthStrings.passwordTooShort;
    }
    return null;
  }

  void _submit() {
    setState(() {
      _isAutovalidating = true;
    });
    
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      _controller.login(
        _emailController.text,
        _passwordController.text,
      );
    }
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
                    // Cabeçalho Curvo Parabólico
                    const AuthHeaderWidget(),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSpacing.verticalSpaceLG,
                          Text(
                            AuthStrings.loginTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: isDark ? AppColors.white : AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.verticalSpaceXS,
                          Text(
                            AuthStrings.loginSubtitle,
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
                                    controller: _emailController,
                                    labelText: AuthStrings.emailLabel,
                                    hintText: AuthStrings.emailHint,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    focusNode: _emailFocusNode,
                                    prefixIcon: LucideIcons.mail,
                                    validator: _validateEmail,
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
                                    textInputAction: TextInputAction.done,
                                    focusNode: _passwordFocusNode,
                                    prefixIcon: LucideIcons.lock,
                                    validator: _validatePassword,
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
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
                                : const Text(AuthStrings.enterButton),
                          ),
                          AppSpacing.verticalSpaceLG,

                          // Login com Google
                          GoogleSignInButton(
                            isDark: isDark,
                            onPressed: isLoading ? null : _controller.signInWithGoogle,
                          ),
                          AppSpacing.verticalSpaceLG,

                          // Navigate to Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AuthStrings.noAccount,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.grey300 : AppColors.grey800,
                                ),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).pushNamed(AppRoutes.signUp);
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AuthStrings.registerNow,
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
}
