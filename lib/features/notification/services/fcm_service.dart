import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_notification_service.dart';

/// Handler de mensagens FCM recebidas com o app em segundo plano ou
/// terminado. TEM de ser uma função de nível superior (ou estática) e
/// anotada com @pragma('vm:entry-point'), porque o sistema operativo invoca-a
/// num isolate próprio, fora do ciclo de vida normal do app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Não é possível atualizar UI aqui (o app pode nem estar visível). O
  // próprio FCM já mostra a notificação de sistema automaticamente quando a
  // mensagem tem um bloco "notification" (ver nota em FCMService sobre
  // payload notification vs data-only). Isto fica apenas como ponto de
  // extensão para lógica adicional em segundo plano, se vier a ser
  // necessária (ex: pré-carregar dados, atualizar badge).
  debugPrint('FCM (background): ${message.messageId}');
}

/// Serviço de Firebase Cloud Messaging (push notifications).
///
/// Complementa o [LocalNotificationService] existente: continua a ser usado
/// para mostrar a notificação no ecrã (inclusive quando a mensagem chega em
/// primeiro plano, caso em que o FCM não mostra nada sozinho), mas agora a
/// origem da notificação pode ser um push do servidor (via Firebase Admin
/// SDK / API HTTP v1), não só a subscrição Realtime em
/// [NotificacaoDataSource.subscribeToChanges].
class FCMService {
  FCMService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Regista o handler de mensagens em segundo plano. Deve ser chamado uma
  /// única vez, o mais cedo possível em main() — antes até de runApp — para
  /// garantir que o handler fica registado mesmo que o app seja terminado.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Pede permissão de notificações (necessário no Android 13+ e no iOS) e
  /// liga os listeners de mensagens em primeiro plano / toque na
  /// notificação. Não pede a permissão automaticamente aqui — à semelhança
  /// do LocalNotificationService, isso é feito explicitamente no ecrã de
  /// permissões do onboarding, para não interromper o utilizador logo ao
  /// abrir o app. Este método assume que a permissão já foi concedida (ou
  /// vai ainda ser) e limita-se a preparar o serviço.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // No Android 12 e anteriores as notificações são permitidas por
      // omissão; no Android 13+ (API 33+) e no iOS é preciso pedir. Chamar
      // requestPermission() aqui é seguro em qualquer versão — em versões
      // antigas devolve "authorized" sem mostrar diálogo nenhum.
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Atualiza o token guardado sempre que o FCM o renovar (acontece
      // periodicamente e após reinstalação/limpeza de dados da app).
      _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

      _initialized = true;
    } catch (e) {
      debugPrint('Falha ao inicializar FCMService: $e');
    }
  }

  /// Pede a permissão de notificações ao utilizador. Chamar explicitamente
  /// no ecrã de permissões do onboarding, junto com Câmara/Localização
  /// (mesmo padrão do LocalNotificationService).
  static Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        await _fetchAndSaveToken();
      }

      return granted;
    } catch (e) {
      debugPrint('Falha ao pedir permissão de notificações (FCM): $e');
      return false;
    }
  }

  /// Obtém o token FCM atual do dispositivo e guarda-o no Supabase, para o
  /// backend (painel admin / função servidor) poder enviar pushes
  /// direcionados a este utilizador.
  static Future<void> _fetchAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('Falha ao obter token FCM: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('utilizador')
          .update({'fcm_token': token})
          .eq('id_utilizador', userId);
    } catch (e) {
      debugPrint('Falha ao gravar token FCM no Supabase: $e');
    }
  }

  /// Mensagem recebida com o app aberto (primeiro plano). O FCM não mostra
  /// nada automaticamente neste caso — por isso, reutilizamos o
  /// LocalNotificationService já existente para exibir a notificação no
  /// dispositivo, mantendo a mesma aparência/canal das notificações locais.
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['titulo'] ?? 'Txeneza';
    final body = message.notification?.body ?? message.data['mensagem'] ?? '';

    await LocalNotificationService.showNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: message.data['id_ocorrencia'] as String?,
    );
  }

  /// Utilizador tocou numa notificação e o app foi aberto/trazido para
  /// primeiro plano a partir dela. Aqui é o sítio certo para navegar
  /// diretamente para o ecrã relevante (ex: detalhe da ocorrência),
  /// usando message.data['id_ocorrencia'] — a ligar à navegação da app
  /// quando esse fluxo for definido.
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notificação FCM tocada: ${message.data}');
    // TODO: navegar para o ecrã da ocorrência usando message.data['id_ocorrencia'],
    // assim que houver uma referência global de navigator/router disponível aqui.
  }
}
