import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/denuncia_draft.dart';
import 'ocorrencia_datasource.dart';

/// Fila offline-first de denúncias por sincronizar.
///
/// Estratégia (decisão do projeto): metadados em `shared_preferences` (JSON) e a
/// foto copiada para a pasta de documentos da app. Sem base de dados local.
class DenunciaQueue {
  static const String _prefsKey = 'denuncia_queue';

  final OcorrenciaDataSource _ocorrenciaDataSource;

  DenunciaQueue({OcorrenciaDataSource? ocorrenciaDataSource})
      : _ocorrenciaDataSource =
            ocorrenciaDataSource ?? OcorrenciaDataSource();

  /// Copia a foto para uma localização persistente da app e grava o draft na
  /// fila. Devolve o draft já com o caminho local definitivo.
  Future<DenunciaDraft> enqueue(
    DenunciaDraft draft,
    String sourceImagePath,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${dir.path}/denuncias_pendentes');
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    final destPath = '${destDir.path}/${draft.id}.jpg';
    await File(sourceImagePath).copy(destPath);

    final persisted = draft.copyWith(fotoPathLocal: destPath);

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    list.add(jsonEncode(persisted.toJson()));
    await prefs.setStringList(_prefsKey, list);

    return persisted;
  }

  Future<List<DenunciaDraft>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    return list
        .map((s) => DenunciaDraft.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<int> pendingCount() async => (await pending()).length;

  Future<void> _remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    list.removeWhere((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList(_prefsKey, list);
  }

  Future<void> _update(DenunciaDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    final index = list.indexWhere((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] == draft.id;
    });
    if (index != -1) {
      list[index] = jsonEncode(draft.toJson());
      await prefs.setStringList(_prefsKey, list);
    }
  }

  /// Tenta submeter todas as denúncias pendentes. Cada sucesso remove o draft e
  /// apaga a foto local. Se forçada pelo utilizador, reinicia as tentativas.
  /// Caso contrário, pula denúncias com falhas persistentes repetidas (> 3 vezes).
  Future<int> flush({bool forceResetTentativas = false}) async {
    List<DenunciaDraft> drafts = await pending();
    
    if (forceResetTentativas) {
      for (var i = 0; i < drafts.length; i++) {
        if (drafts[i].tentativas > 0) {
          drafts[i] = drafts[i].copyWith(tentativas: 0, ultimoErro: null);
          await _update(drafts[i]);
        }
      }
    }

    int sincronizadas = 0;

    for (final draft in drafts) {
      // Pula rascunhos que já falharam consecutivamente mais de 3 vezes por erro não de rede.
      if (draft.tentativas >= 3) {
        continue;
      }

      try {
        await _ocorrenciaDataSource.submit(draft);
        await _remove(draft.id);
        final f = File(draft.fotoPathLocal);
        if (await f.exists()) await f.delete();
        sincronizadas++;
      } catch (e) {
        final errorStr = e.toString();
        debugPrint('Falha ao sincronizar denúncia ${draft.id}: $e');

        // Se for erro de rede/timeout, para o loop para evitar martelar
        final isNetworkError = errorStr.contains('SocketException') ||
            errorStr.contains('ClientException') ||
            errorStr.contains('TimeoutException') ||
            errorStr.contains('Connection failed') ||
            errorStr.contains('Failed host lookup');

        if (isNetworkError) {
          break;
        } else {
          // Erro lógico/estrutural/permissão: incrementa tentativas para não travar a fila.
          final updated = draft.copyWith(
            tentativas: draft.tentativas + 1,
            ultimoErro: errorStr,
          );
          await _update(updated);
          continue;
        }
      }
    }
    return sincronizadas;
  }
}
