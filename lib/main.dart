import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/error/error_mapper.dart';
import 'core/locale/locale_resolution.dart';
import 'core/locale/locale_cubit.dart';
import 'core/navigation/route_observer.dart';
import 'core/supabase/artbook_supabase.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/app_update_gate.dart';
import 'features/auth/data/repository/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/pages/main_shell.dart';
import 'l10n/app_localizations.dart';
import 'features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ArtBook uses Supabase Auth, Postgres and Storage. There is no Bagisto
  // server bootstrap in the ArtBook runtime.
  await ArtBookSupabase.initialize();

  final prefs = await SharedPreferences.getInstance();
  runApp(ArtBookApp(prefs: prefs));
}

class ArtBookApp extends StatelessWidget {
  final SharedPreferences prefs;

  const ArtBookApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepository(client: ArtBookSupabase.client),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()..initialize(prefs)),
          BlocProvider(create: (_) => LocaleCubit()..initialize(prefs)),
          BlocProvider(
            create: (ctx) => AuthBloc(
              repository: ctx.read<AuthRepository>(),
            )..add(const AuthCheckStatus()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) => BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              ErrorMapper.updateLocale(
                resolveAppLocale(locale, AppLocalizations.supportedLocales),
              );
              return MaterialApp(
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.appTitle,
                debugShowCheckedModeBanner: false,
                navigatorObservers: [appRouteObserver],
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                localeResolutionCallback: (deviceLocale, supported) =>
                    resolveAppLocale(locale ?? deviceLocale, supported),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.noScaling),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: SplashScreen(
                  nextScreen: AppUpdateGate(
                    child: MainShell(key: MainShell.navigatorKey),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
