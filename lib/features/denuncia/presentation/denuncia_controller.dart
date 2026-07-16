import 'package:flutter/foundation.dart';

import '../data/denuncia_queue.dart';
import '../data/ocorrencia_datasource.dart';
import '../domain/denuncia_draft.dart';

enum DenunciaStatus { idle, submitting, sentOnline, queuedOffline, error }

/// Orquestra a submissão de uma denúncia com estratégia offline-first:
/// online tenta enviar já; sem rede (ou se o envio falhar) guarda na fila.
class DenunciaController extends ChangeNotifier {
  final OcorrenciaDataSource _ocorrencia;
  final DenunciaQueue _queue;

  DenunciaController({
    OcorrenciaDataSource? ocorrencia,
    DenunciaQueue? queue,
  })  : _ocorrencia = ocorrencia ?? OcorrenciaDataSource(),
        _queue = queue ?? DenunciaQueue();

  DenunciaStatus _status = DenunciaStatus.idle;
  DenunciaStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isSubmitting => _status == DenunciaStatus.submitting;

  /// Submete a denúncia. [isOnline] vem do estado de conectividade da app.
  /// [sourceImagePath] é a foto original capturada pela câmara.
  Future<void> submit({
    required DenunciaDraft draft,
    required String sourceImagePath,
    required bool isOnline,
  }) async {
    _status = DenunciaStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    // Sem rede: vai direto para a fila.
    if (!isOnline) {
      await _enqueue(draft, sourceImagePath);
      return;
    }

    // Online: tenta enviar; se falhar (rede instável), cai para a fila em vez
    // de perder a denúncia.
    try {
      final ready = draft.copyWith(fotoPathLocal: sourceImagePath);
      await _ocorrencia.submit(ready);
      _status = DenunciaStatus.sentOnline;
    } catch (e) {
      debugPrint('Envio online falhou, a guardar na fila: $e');
      await _enqueue(draft, sourceImagePath);
      return;
    }
    notifyListeners();
  }

  Future<void> _enqueue(DenunciaDraft draft, String sourceImagePath) async {
    try {
      await _queue.enqueue(draft, sourceImagePath);
      _status = DenunciaStatus.queuedOffline;
    } catch (e) {
      _status = DenunciaStatus.error;
      _errorMessage = 'Não foi possível guardar a denúncia no dispositivo.';
    }
    notifyListeners();
  }
}
