class AuthStrings {
  AuthStrings._();

  // Login
  static const String loginTitle = 'Bem-vindo de volta';
  static const String loginSubtitle = 'Introduza os seus dados para aceder à sua conta e reportar ocorrências.';
  static const String emailLabel = 'E-mail';
  static const String emailHint = 'exemplo@email.com';
  static const String passwordLabel = 'Palavra-passe';
  static const String passwordHint = 'Introduza a sua palavra-passe';
  static const String enterButton = 'Entrar';
  static const String processing = 'A processar...';
  static const String noAccount = 'Não tem uma conta? ';
  static const String registerNow = 'Registe-se';
  static const String loginSuccess = 'Login efetuado com sucesso!';
  static const String loginError = 'E-mail ou palavra-passe incorretos. Por favor, tente novamente.';

  // Sign Up
  static const String signUpTitle = 'Criar Conta';
  static const String signUpSubtitle = 'Preencha os campos abaixo para se registar na plataforma Txeneza.';
  static const String fullNameLabel = 'Nome completo';
  static const String fullNameHint = 'Ex: João Manuel';
  static const String phoneLabel = 'Número de celular';
  static const String phoneHint = 'Ex: 84 123 4567';
  static const String neighborhoodLabel = 'Bairro';
  static const String neighborhoodHint = 'Selecione o seu bairro';
  static const String signUpButton = 'Criar conta';
  static const String hasAccount = 'Já tem uma conta? ';
  static const String loginNow = 'Inicie sessão';
  static const String signUpSuccess = 'Conta criada com sucesso! Por favor, faça o login.';
  static const String signUpPendingConfirmation = 'Conta criada! Verifique o seu e-mail para confirmar o registo antes de iniciar sessão.';
  static const String signUpError = 'Ocorreu um erro ao criar a conta. Tente novamente.';

  // Login social
  static const String orDivider = 'ou';
  static const String continueWithGoogle = 'Continuar com Google';
  static const String genericAuthError = 'Não foi possível concluir a operação. Tente novamente.';

  // Validações
  static const String emailRequired = 'O e-mail é obrigatório.';
  static const String emailInvalid = 'Introduza um e-mail válido.';
  static const String passwordRequired = 'A palavra-passe é obrigatória.';
  static const String passwordTooShort = 'A palavra-passe deve ter no mínimo 8 caracteres.';
  static const String passwordStrength = 'A palavra-passe deve conter letras maiúsculas, minúsculas e números.';
  
  static const String fullNameRequired = 'O nome completo é obrigatório.';
  static const String fullNameTwoWords = 'O nome deve conter pelo menos 2 palavras.';
  
  static const String phoneRequired = 'O número de celular é obrigatório.';
  static const String phoneInvalid = 'Use um celular válido de Moçambique (iniciando com 82, 83, 84, 85, 86 ou 87).';
  
  static const String neighborhoodRequired = 'A seleção de bairro é obrigatória.';
}
