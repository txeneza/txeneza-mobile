import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../map/domain/occurrence_model.dart';
import '../widgets/my_reports_view.dart';

/// Standalone page wrapper for MyReportsView, accessible via named route.
/// Provides its own mock occurrence data independently of HomeScreen.
class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  // Mock occurrences (same dataset as HomeScreen for consistency)
  static const List<Occurrence> _mockOccurrences = [
    Occurrence(
      id: '1',
      position: LatLng(-19.8380, 34.8380),
      status: OccurrenceStatus.pending,
      title: 'Acúmulo de Lixo - Ponta Gêa',
      description: 'Resíduos domésticos descartados na berma da estrada.',
    ),
    Occurrence(
      id: '2',
      position: LatLng(-19.8350, 34.8410),
      status: OccurrenceStatus.critical,
      title: 'Lixeira Irregular - Centro',
      description: 'Grande quantidade de plásticos acumulados obstruindo a calçada.',
    ),
    Occurrence(
      id: '3',
      position: LatLng(-19.8100, 34.8150),
      status: OccurrenceStatus.critical,
      title: 'Resíduos de Mercado - Munhava',
      description: 'Restos orgânicos atraindo pragas no mercado local.',
    ),
    Occurrence(
      id: '4',
      position: LatLng(-19.8150, 34.8100),
      status: OccurrenceStatus.pending,
      title: 'Foco de Lixo - Munhava',
      description: 'Entulho acumulado há mais de duas semanas.',
    ),
    Occurrence(
      id: '5',
      position: LatLng(-19.8080, 34.8200),
      status: OccurrenceStatus.resolved,
      title: 'Limpeza Efetuada - Munhava',
      description: 'Zona de lixeira eliminada e revitalizada.',
    ),
    Occurrence(
      id: '6',
      position: LatLng(-19.8250, 34.8700),
      status: OccurrenceStatus.pending,
      title: 'Lixo na Praia - Macuti',
      description: 'Garrafas plásticas e redes de pesca abandonadas na areia.',
    ),
    Occurrence(
      id: '7',
      position: LatLng(-19.8280, 34.8750),
      status: OccurrenceStatus.resolved,
      title: 'Ação de Limpeza - Macuti',
      description: 'Voluntários recolheram detritos na orla marítima.',
    ),
    Occurrence(
      id: '8',
      position: LatLng(-19.8200, 34.8680),
      status: OccurrenceStatus.pending,
      title: 'Lixeira de Estrada - Macuti',
      description: 'Sacos de lixo rasgados espalhados pelo vento.',
    ),
    Occurrence(
      id: '9',
      position: LatLng(-19.8200, 34.8450),
      status: OccurrenceStatus.resolved,
      title: 'Vala Desobstruída - Esturro',
      description: 'Retirada de resíduos sólidos que impediam o fluxo de água.',
    ),
    Occurrence(
      id: '10',
      position: LatLng(-19.8180, 34.8500),
      status: OccurrenceStatus.resolved,
      title: 'Contentor Esvaziado - Chota',
      description: 'Limpeza de contentor público saturado.',
    ),
  ];

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
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : AppColors.forestGreen,
          ),
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
      body: const MyReportsView(
        occurrences: _mockOccurrences,
      ),
    );
  }
}
