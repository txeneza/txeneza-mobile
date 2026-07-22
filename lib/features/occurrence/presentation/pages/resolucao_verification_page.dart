import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../data/resolucao_datasource.dart';
import '../../domain/resolucao_verificacao.dart';

/// Ecrã do ciclo de verificação fotográfica da resolução pelo morador.
class ResolucaoVerificationPage extends StatefulWidget {
  final String occurrenceId;
  final String occurrenceTitle;

  const ResolucaoVerificationPage({
    super.key,
    required this.occurrenceId,
    required this.occurrenceTitle,
  });

  @override
  State<ResolucaoVerificationPage> createState() => _ResolucaoVerificationPageState();
}

class _ResolucaoVerificationPageState extends State<ResolucaoVerificationPage> {
  final _dataSource = ResolucaoDataSource();
  final _picker = ImagePicker();
  final _comentarioController = TextEditingController();

  ResolucaoVerificacao? _verificacao;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String? _contestacaoPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadVerificacao();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _loadVerificacao() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _dataSource.fetchVerificacao(widget.occurrenceId);
      if (!mounted) return;
      setState(() {
        _verificacao = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao carregar dados de verificação: $e';
      });
    }
  }

  Future<void> _tirarFotoContestacao() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (photo == null) return;
    setState(() => _contestacaoPhotoPath = photo.path);
  }

  Future<void> _submeterDecisao(bool aprovado) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _dataSource.submitVerificacao(
        idOcorrencia: widget.occurrenceId,
        aprovado: aprovado,
        observacoes: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
        fotoContestacaoLocalPath: _contestacaoPhotoPath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aprovado
                ? 'Resolução confirmada com sucesso! Obrigado pela colaboração.'
                : 'Contestação enviada. A denúncia foi reaberta para fiscalização.',
            style: const TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: aprovado ? AppColors.forestGreen : const Color(0xFFE65100),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao submeter: $e', style: const TextStyle(fontFamily: 'Geist')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verificação de Resolução',
          style: TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(fontFamily: 'Geist')),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadVerificacao,
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(isDark),
                      const SizedBox(height: 20),
                      _buildComparisonSection(isDark),
                      const SizedBox(height: 20),
                      if (_verificacao?.statusVerificacao == StatusVerificacaoMorador.pendente) ...[
                        _buildActionSection(isDark),
                      ] else ...[
                        _buildAlreadyVerifiedBadge(isDark),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.occurrenceTitle,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(LucideIcons.checkCheck, size: 16, color: AppColors.forestGreen),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A equipa municipal marcou esta denúncia como limpa/resolvida.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : AppColors.grey800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comprovação Fotográfica',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPhotoCard(
                title: 'Foto Inicial',
                url: _verificacao?.fotoInicialUrl,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPhotoCard(
                title: 'Foto de Resolução',
                url: _verificacao?.fotoResolucaoUrl,
                isDark: isDark,
                isHighlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String? url,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : AppColors.grey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight
              ? AppColors.forestGreen
              : (isDark ? Colors.white24 : AppColors.grey300),
          width: isHighlight ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(title, isDark),
              )
            : _buildPlaceholder(title, isDark),
      ),
    );
  }

  Widget _buildPlaceholder(String title, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, color: isDark ? Colors.white38 : AppColors.grey600),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.grey800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyVerifiedBadge(bool isDark) {
    final status = _verificacao!.statusVerificacao;
    final isApproved = status == StatusVerificacaoMorador.aprovado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isApproved
            ? AppColors.forestGreen.withValues(alpha: 0.10)
            : AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved ? AppColors.forestGreen : AppColors.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? LucideIcons.circleCheck : LucideIcons.circleAlert,
            color: isApproved ? AppColors.forestGreen : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isApproved
                  ? 'Você já confirmou que esta denúncia foi resolvida com sucesso.'
                  : 'Você contestou esta resolução. A ocorrência foi reaberta.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isApproved ? AppColors.forestGreen : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validação do Morador',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _comentarioController,
          maxLines: 2,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
          decoration: InputDecoration(
            hintText: 'Comentário opcional (ex: local limpo, nada a apontar)...',
            hintStyle: const TextStyle(fontFamily: 'Geist', fontSize: 12.5, color: AppColors.grey600),
            filled: true,
            fillColor: isDark ? DarkColors.surface : AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_contestacaoPhotoPath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_contestacaoPhotoPath!),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _submeterDecisao(true),
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text('Confirmar', style: TextStyle(fontFamily: 'Geist', fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_contestacaoPhotoPath == null) {
                          await _tirarFotoContestacao();
                        }
                        if (_contestacaoPhotoPath != null) {
                          await _submeterDecisao(false);
                        }
                      },
                icon: const Icon(LucideIcons.triangleAlert, size: 16),
                label: Text(
                  _contestacaoPhotoPath == null ? 'Contestar (Foto)' : 'Enviar Contestação',
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100),
                  side: const BorderSide(color: Color(0xFFE65100)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
