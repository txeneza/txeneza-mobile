import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/my_report.dart';
import '../widgets/my_reports_view.dart';

/// Lista as ocorrências reais submetidas pelo próprio utilizador.
class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _repository = ProfileRepositoryImpl();

  bool _loading = true;
  String? _error;
  List<MyReport> _reports = [];
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  /// Subscreve alterações na tabela "ocorrencia" para este utilizador.
  /// Sempre que o estado mudar no servidor/web, a lista atualiza-se sozinha em tempo real.
  void _subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _realtimeChannel = Supabase.instance.client
          .channel('realtime_minhas_ocorrencias_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'ocorrencia',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id_utilizador',
              value: userId,
            ),
            callback: (payload) => _load(showLoading: false),
          );
      _realtimeChannel?.subscribe();
    } catch (e) {
      debugPrint('Erro ao subscrever Realtime em MyReportsPage: $e');
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final reports = await _repository.getMyReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.grey900 : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: isDark ? Colors.white : AppColors.forestGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Minhas Ocorrências',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.forestGreen,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.refreshCw,
              size: 20,
              color: isDark ? Colors.white70 : AppColors.forestGreen,
            ),
            tooltip: 'Atualizar',
            onPressed: () => _load(),
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.triangleAlert,
                  size: 40, color: isDark ? Colors.white38 : AppColors.grey600),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.grey800,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Tentar Novamente',
                    style: TextStyle(fontFamily: 'Geist')),
              ),
            ],
          ),
        ),
      );
    }

    return MyReportsView(
      reports: _reports,
      onRefresh: () => _load(showLoading: false),
      onItemReturned: () => _load(showLoading: false),
    );
  }
}
