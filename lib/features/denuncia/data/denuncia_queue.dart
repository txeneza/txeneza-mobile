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

  /// Tenta submeter todas as denúncias pendentes. Cada sucesso remove o draft e
  /// apaga a foto local. Uma falha (rede) deixa o draft na fila para a próxima
  /// tentativa. Devolve quantas foram sincronizadas.
  Future<int> flush() async {
    final drafts = await pending();
    int sincronizadas = 0;

    for (final draft in drafts) {
      try {
        await _ocorrenciaDataSource.submit(draft);
        await _remove(draft.id);
        final f = File(draft.fotoPathLocal);
        if (await f.exists()) await f.delete();
        sincronizadas++;
      } catch (e) {
        // Sem rede ou erro temporário: mantém na fila e para (evita martelar).
        debugPrint('Falha ao sincronizar denúncia ${draft.id}: $e');
        break;
      }
    }
    return sincronizadas;
  }
}
