import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';

import 'screens/root_screen.dart';
import 'screens/sign_in_page.dart';
import 'screens/sign_up_page.dart';
import 'theme/app_theme.dart';
import 'settings/settings_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController();
  runApp(NovelApp(settings: settings));
}

class NovelApp extends StatelessWidget {
  final SettingsController settings;

  const NovelApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'Novel App',

          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,

          locale: settings.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('pl'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: RootScreen(settings: settings),

          routes: {
            '/signin': (context) => const SignInPage(),
            '/signup': (context) => const SignUpPage(),
          },
        );
      },
    );
  }
}
