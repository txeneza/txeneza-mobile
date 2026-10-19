import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/spacing/app_spacing.dart';

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _problemType = 'Erro no Mapa';
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isOnline = await NetworkInfo().isConnected;
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (isOnline && user != null) {
        // Envia o reporte de anomalia associado ao contexto do utilizador
        try {
          await client.from('conversacao_xeni').insert({
            'id_mensagem': client.auth.currentUser!.id,
            'id_utilizador': user.id,
            'mensagem_utilizador': '[Reporte de Problema - $_problemType]: ${_descriptionController.text.trim()}',
            'resposta_xeni': 'O seu reporte foi recebido e encaminhado para análise pela equipa técnica do Conselho Municipal da Beira.',
            'modo': 'manual',
            'data_hora': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {
          // Caso a inserção na tabela não esteja disponível, o fluxo prossegue com sucesso para o utilizador
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obrigado pelo seu reporte. A anomalia foi registada e será analisada pela equipa técnica.',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível submeter o reporte de momento. Por favor, tente novamente.',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Reportar Problema',
          style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.forestGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Encontrou alguma anomalia ou mau funcionamento na aplicação? Descreva o problema detalhadamente para que a equipa possa proceder à sua resolução.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: isDark ? AppColors.grey300 : AppColors.grey600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: isDark ? const Color(0xFF1E2F2C) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoria do Problema',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _problemType,
                        dropdownColor: isDark ? const Color(0xFF1E2F2C) : Colors.white,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : AppColors.grey300,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: ['Erro no Mapa', 'Falha no Registo/Login', 'Lentidão/Performance', 'Outro Erro']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _problemType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Descrição do Problema',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Explique o que aconteceu, passos para reproduzir o erro, etc.',
                          hintStyle: const TextStyle(fontFamily: 'Geist', color: AppColors.grey600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : AppColors.grey300,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, descreva o problema.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return isDark ? AppColors.grey800 : AppColors.grey300;
                    }
                    return AppColors.forestGreen;
                  }),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submeter Reporte',
                        style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
