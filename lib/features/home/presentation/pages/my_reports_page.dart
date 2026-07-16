import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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

    return MyReportsView(reports: _reports);
  }
}
