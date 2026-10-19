import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:txeneza_app/core/config/env/app_env.dart';
import 'package:txeneza_app/features/denuncia/data/ocorrencia_datasource.dart';
import 'package:txeneza_app/features/denuncia/domain/denuncia_draft.dart';
import 'package:txeneza_app/features/denuncia/domain/gravidade.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class DenunciaAlvo {
  final String bairro;
  final double latitude;
  final double longitude;
  final String caminhoImagem;
  final String descricao;
  final Gravidade gravidade;

  const DenunciaAlvo({
    required this.bairro,
    required this.latitude,
    required this.longitude,
    required this.caminhoImagem,
    required this.descricao,
    required this.gravidade,
  });
}

/// Executa a rotina de submissão de denúncias para os bairros solicitados da Beira.
Future<void> executarDenunciasBeira({
  String? email,
  String? password,
}) async {
  stdout.writeln('====================================================');
  stdout.writeln('INÍCIO DA SUBMISSÃO DE DENÚNCIAS - MUNICÍPIO DA BEIRA');
  stdout.writeln('====================================================');

  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  SharedPreferences.setMockInitialValues({});

  // 1. Carregamento das variáveis de ambiente
  final envFile = File('.env');
  if (await envFile.exists()) {
    try {
      await dotenv.load(fileName: '.env');
      stdout.writeln('Ficheiro .env carregado com sucesso.');
    } catch (e) {
      stdout.writeln('Aviso ao carregar .env: $e');
    }
  }

  // 2. Inicialização do Supabase
  final supabaseUrl = AppEnv.supabaseUrl.isNotEmpty
      ? AppEnv.supabaseUrl
      : (Platform.environment['SUPABASE_URL'] ?? '');
  final supabaseAnonKey = AppEnv.supabaseAnonKey.isNotEmpty
      ? AppEnv.supabaseAnonKey
      : (Platform.environment['SUPABASE_ANON_KEY'] ?? '');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Configurações do Supabase ausentes. Defina SUPABASE_URL e SUPABASE_ANON_KEY no ficheiro .env ou no ambiente.',
    );
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    stdout.writeln('Supabase inicializado: $supabaseUrl');
  } catch (e) {
    stdout.writeln('Supabase já inicializado ou informação reaproveitada: $e');
  }

  final client = Supabase.instance.client;

  // 3. Autenticação do utilizador de teste
  var utilizadorAtual = client.auth.currentUser;
  if (utilizadorAtual == null) {
    final authEmail = email ??
        dotenv.maybeGet('TEST_USER_EMAIL') ??
        Platform.environment['TEST_USER_EMAIL'];
    final authPassword = password ??
        dotenv.maybeGet('TEST_USER_PASSWORD') ??
        Platform.environment['TEST_USER_PASSWORD'];

    if (authEmail != null &&
        authEmail.isNotEmpty &&
        authPassword != null &&
        authPassword.isNotEmpty) {
      stdout.writeln('A iniciar sessão com o utilizador de teste: $authEmail');
      final authResponse = await client.auth.signInWithPassword(
        email: authEmail.trim().toLowerCase(),
        password: authPassword,
      );
      utilizadorAtual = authResponse.user;
    }
  }

  if (utilizadorAtual == null) {
    throw StateError(
      'Autenticação obrigatória: É necessária uma sessão ativa para submeter denúncias no Supabase.',
    );
  }

  stdout.writeln('Utilizador autenticado: ${utilizadorAtual.id} (${utilizadorAtual.email ?? 'sem e-mail'})');

  // 4. Obtenção de categorias da base de dados
  String idCategoriaPadrao = '6950f0f5-a9ec-4d9c-b65a-466426ab8729';
  Map<String, String> categoriasPorNome = {};
  try {
    final response = await client
        .from('categoria_residuo')
        .select('id_categoria, nome')
        .order('nome');
    final rows = (response as List).cast<Map<String, dynamic>>();
    for (final row in rows) {
      final nome = (row['nome'] as String).toLowerCase();
      final id = row['id_categoria'] as String;
      categoriasPorNome[nome] = id;
    }
    if (categoriasPorNome.isNotEmpty) {
      idCategoriaPadrao = categoriasPorNome.values.first;
      stdout.writeln('Categorias registadas carregadas: ${categoriasPorNome.length}');
    }
  } catch (e) {
    stdout.writeln('Aviso ao consultar categorias do Supabase: $e');
  }

  // 5. Definição dos 6 alvos municipais da Beira (formato 9:16 vertical de telemóvel)
  final List<DenunciaAlvo> alvos = [
    DenunciaAlvo(
      bairro: 'Inhamizua',
      latitude: -19.7252,
      longitude: 34.8141,
      caminhoImagem: r'c:\Users\PC\Desktop\projecto\txeneza-mobile\test\fotos_denuncias\inhamizua_9_16.jpg',
      descricao: 'Acumulação descontrolada de resíduos domésticos e embalagens plásticas na valeta da via principal, a obstruir o escoamento pluvial.',
      gravidade: Gravidade.alta,
    ),
    DenunciaAlvo(
      bairro: 'Manga',
      latitude: -19.7890,
      longitude: 34.8750,
      caminhoImagem: r'c:\Users\PC\Desktop\projecto\txeneza-mobile\test\fotos_denuncias\manga_9_16.jpg',
      descricao: 'Depósito informal de sacos de lixo e detritos junto à berma da estrada pavimentada, com proliferação de vetores.',
      gravidade: Gravidade.media,
    ),
    DenunciaAlvo(
      bairro: 'Maraza',
      latitude: -19.8080,
      longitude: 34.8685,
      caminhoImagem: r'c:\Users\PC\Desktop\projecto\txeneza-mobile\test\fotos_denuncias\maraza_9_16.jpg',
      descricao: 'Ponto crítico de lixo a céu aberto no areal entre habitações, com restos orgânicos e plásticos em decomposição.',
      gravidade: Gravidade.alta,
    ),
    DenunciaAlvo(
      bairro: 'Ndunda',
      latitude: -19.7520,
      longitude: 34.8380,
      caminhoImagem: r'c:\Users\PC\Desktop\projecto\txeneza-mobile\test\fotos_denuncias\ndunda_9_16.jpg',
      descricao: 'Lixeira clandestina na periferia do bairro, contendo resíduos mistos descartados desordenadamente na vegetação.',
      gravidade: Gravidade.baixa,
    ),
    DenunciaAlvo(
      bairro: 'Pioneiros',
      latitude: -19.8260,
      longitude: 34.8480,
      caminhoImagem: r'c:\Users\PC\Desktop\projecto\txeneza-mobile\test\fotos_denuncias\pioneiros_9_16.jpg',
      descricao: 'Descarte ilícito de sucata, detritos industriais e embalagens pesadas na zona de armazéns e circulação de viaturas.',
      gravidade: Gravidade.alta,
    ),
    DenunciaAlvo(
      bairro: 'Munhava',
      latitude: -19.8150,
      longitude: 34.8450,
      caminhoImagem: r'c:\Users\PC\Desktop\projecto\txeneza-mobile\test\fotos_denuncias\munhava_9_16.jpg',
      descricao: 'Monte de lixo acumulado em cruzamento residencial movimentado, gerando odores fétidos e impedindo a passagem pedonal.',
      gravidade: Gravidade.alta,
    ),
  ];

  final dataSource = OcorrenciaDataSource();

  // 6. Submissão sequencial de cada denúncia
  for (int i = 0; i < alvos.length; i++) {
    final alvo = alvos[i];
    final file = File(alvo.caminhoImagem);
    if (!await file.exists()) {
      stdout.writeln('Aviso: Imagem não encontrada para o bairro ${alvo.bairro}: ${alvo.caminhoImagem}');
      continue;
    }

    final idDenuncia = const Uuid().v4();
    final draft = DenunciaDraft(
      id: idDenuncia,
      latitude: alvo.latitude,
      longitude: alvo.longitude,
      descricao: alvo.descricao,
      idCategoria: idCategoriaPadrao,
      gravidade: alvo.gravidade,
      fotoPathLocal: alvo.caminhoImagem,
      dataHoraRegisto: DateTime.now(),
    );

    stdout.writeln('\n[${i + 1}/${alvos.length}] A submeter denúncia para o bairro ${alvo.bairro}...');
    stdout.writeln('  - ID: $idDenuncia');
    stdout.writeln('  - Coordenadas: (${draft.latitude}, ${draft.longitude})');
    stdout.writeln('  - Ficheiro 9:16: ${alvo.caminhoImagem} (${await file.length()} bytes)');

    try {
      await dataSource.submit(draft);
      stdout.writeln('  -> Submissão concluída com sucesso para o bairro ${alvo.bairro}.');
    } catch (e) {
      stdout.writeln('  -> Erro na submissão de ${alvo.bairro}: $e');
    }
  }

  stdout.writeln('\n====================================================');
  stdout.writeln('SUBMISSÃO DAS 6 DENÚNCIAS CONCLUÍDA');
  stdout.writeln('====================================================');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Submissão sequencial de 6 denúncias com imagens verticais 9:16 na Beira', () async {
    await HttpOverrides.runWithHttpOverrides(
      () => executarDenunciasBeira(),
      _RealHttpOverrides(),
    );
  });
}
