import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Gere a verificação de conectividade física e validação de tráfego real à internet,
/// prevenindo falsos positivos causados por cache de DNS, portais cativos ou interfaces ativas sem rota externa.
class NetworkInfo {
  static final NetworkInfo _instance = NetworkInfo._internal();
  factory NetworkInfo() => _instance;
  NetworkInfo._internal();

  final Connectivity _connectivity = Connectivity();

  bool? _lastKnownStatus;
  DateTime? _lastCheckTime;
  static const Duration _cacheDuration = Duration(seconds: 2);

  /// Verifica se existe interface de rede ativa e ligação com tráfego real à internet.
  Future<bool> get isConnected async => checkRealConnection();

  /// Executa o diagnóstico completo de ligação real à internet.
  /// Se [force] for falso, reaproveita o resultado recente dentro do intervalo de tolerância (2 segundos).
  Future<bool> checkRealConnection({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastKnownStatus != null &&
        _lastCheckTime != null &&
        now.difference(_lastCheckTime!) < _cacheDuration) {
      return _lastKnownStatus!;
    }

    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _lastKnownStatus = false;
      _lastCheckTime = now;
      return false;
    }

    final hasAccess = await hasRealInternetAccess();
    _lastKnownStatus = hasAccess;
    _lastCheckTime = DateTime.now();
    return hasAccess;
  }

  /// Valida se o dispositivo consegue estabelecer comunicação com a internet pública.
  /// Combina ligação por socket direto a servidores de transporte e prova HTTP (código 204),
  /// eliminando falsos positivos decorrentes de portais cativos e caches locais de DNS.
  Future<bool> hasRealInternetAccess() async {
    if (kIsWeb) {
      return await _probeHttp();
    }

    // 1. Prova de transporte direto via Socket IP (ignora cache de DNS local do sistema operativo)
    final socketOk = await _probeSocket();
    if (!socketOk) {
      return false;
    }

    // 2. Prova de tráfego HTTP para descartar portais cativos (Wi-Fi com login ou dados móveis bloqueados)
    return await _probeHttp();
  }

  Future<bool> _probeSocket() async {
    // Tenta ligar diretamente a servidores de infraestrutura pública global na porta 53 (DNS)
    final targets = [
      ('1.1.1.1', 53),
      ('8.8.8.8', 53),
    ];

    for (final target in targets) {
      try {
        final socket = await Socket.connect(
          target.$1,
          target.$2,
          timeout: const Duration(milliseconds: 1500),
        );
        socket.destroy();
        return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  Future<bool> _probeHttp() async {
    // URLs canónicas com retorno padrão HTTP 204 (No Content).
    // Portais cativos interceptam a rota e devolvem códigos 200, 301 ou 302 com páginas HTML.
    final endpoints = [
      Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
      Uri.parse('https://www.google.com/generate_204'),
    ];

    for (final uri in endpoints) {
      try {
        final response = await http
            .get(uri)
            .timeout(const Duration(milliseconds: 2500));
        if (response.statusCode == 204) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }

    // Fallback de contingência caso a rota 204 esteja filtrada por regras específicas do operador
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 1500));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Expõe um Stream com mudanças de conectividade filtradas por verificação de tráfego real.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .asyncMap((results) async {
          if (results.isEmpty || results.contains(ConnectivityResult.none)) {
            _lastKnownStatus = false;
            _lastCheckTime = DateTime.now();
            return false;
          }
          return await checkRealConnection(force: true);
        })
        .distinct();
  }
}
