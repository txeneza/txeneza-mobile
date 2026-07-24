import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Gerencia a verificação de conectividade física e valida a ligação real à internet.
class NetworkInfo {
  static final NetworkInfo _instance = NetworkInfo._internal();
  factory NetworkInfo() => _instance;
  NetworkInfo._internal();

  final Connectivity _connectivity = Connectivity();

  /// Verifica se há uma interface de rede activa E acesso real à internet.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }
    if (kIsWeb) return true;
    return await hasRealInternetAccess();
  }

  /// Verifica se há tráfego de dados real fazendo lookup DNS para domínios confiáveis.
  Future<bool> hasRealInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        // Fallback rápido se o google falhar por problemas de roteamento específicos.
        final result = await InternetAddress.lookup('one.one.one.one')
            .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Expõe um Stream de mudanças de conectividade, validando o acesso real à internet.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        return false;
      }
      if (kIsWeb) return true;
      return await hasRealInternetAccess();
    });
  }
}
