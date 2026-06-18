import 'package:flutter/material.dart';
import 'core/theme/theme_controller/theme_provider.dart';
import 'core/theme/theme_data/light_theme.dart';
import 'core/theme/theme_data/dark_theme.dart';
import 'core/theme/spacing/app_spacing.dart';
import 'core/theme/icons/app_icons.dart';

final themeProvider = ThemeProvider();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Txeneza App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Txeneza - Olá Paulo'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? AppIcons.info : AppIcons.sync,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Alterar Tema',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Olá, Paulo!',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSpacing.verticalSpaceMD,
              Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Design Tokens',
                      style: theme.textTheme.headlineMedium,
                    ),
                    AppSpacing.verticalSpaceSM,
                    Text(
                      'Este card demonstra a aplicação dos novos tokens de design. '
                      'O espaçamento é baseado no grid de 8px e as cores usam a paleta configurada.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpaceLG,
            ElevatedButton(
              onPressed: () {
                // Demonstração da área mínima de clique de 48px
              },
              child: const Text('Botão de Exemplo (Touch Target 48px)'),
            ),
          ],
        ),
      ),),
    );
  }
}
