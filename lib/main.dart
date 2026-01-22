import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/constants/app_colors.dart';
import 'package:expense_tracker/controls/spending_repository.dart';
import 'package:expense_tracker/page/lock/app_lock_page.dart';
import 'package:expense_tracker/page/main/home/home_page.dart';
import 'package:expense_tracker/page/main/main_page.dart';
import 'package:expense_tracker/page/onboarding/onboarding_page.dart';
import 'package:expense_tracker/setting/bloc/setting_cubit.dart';
import 'package:expense_tracker/setting/bloc/setting_state.dart';
import 'package:expense_tracker/setting/localization/app_localizations_setup.dart';

int? language;
bool isDark = false;
bool isFirstStart = true;
bool appLockEnabled = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpendingRepository.init();
  final prefs = await SharedPreferences.getInstance();
  language = prefs.getInt('language');
  isDark = prefs.getBool("isDark") ?? false;
  isFirstStart = prefs.getBool("firstStart") ?? true;
  appLockEnabled = prefs.getBool("app_lock_enabled") ?? false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((value) {
      value.setBool("firstStart", false);
    });
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingCubit>(
          create: (_) => SettingCubit(language: language, isDark: isDark),
        ),
      ],
      child: BlocBuilder<SettingCubit, SettingState>(
        buildWhen: (previous, current) => previous != current,
        builder: (_, settingState) {
          final ThemeData lightTheme = ThemeData(
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(background: Colors.white),
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            bottomAppBarTheme: const BottomAppBarThemeData(
              color: Colors.white,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromRGBO(121, 158, 84, 1),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.white,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            primaryColor: Colors.white,
          );

          final ThemeData darkTheme = ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme:
                const ColorScheme.dark(background: Color(0xFF121212)),
            bottomAppBarTheme: const BottomAppBarThemeData(
              color: Color(0xFF121212),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromRGBO(121, 158, 84, 1),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
          );

          final theme = settingState.isDark ? darkTheme : lightTheme;

          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: theme.scaffoldBackgroundColor,
              statusBarIconBrightness: settingState.isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: settingState.isDark
                  ? Brightness.dark
                  : Brightness.light,
              systemNavigationBarColor: theme.scaffoldBackgroundColor,
              systemNavigationBarIconBrightness: settingState.isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            supportedLocales: AppLocalizationsSetup.supportedLocales,
            localizationsDelegates:
                AppLocalizationsSetup.localizationsDelegates,
            localeResolutionCallback:
                AppLocalizationsSetup.localeResolutionCallback,
            locale: settingState.locale,
            debugShowCheckedModeBanner: false,
            title: 'Spending Management',
            theme: theme,
            initialRoute:
                isFirstStart ? "/" : (appLockEnabled ? "/unlock" : "/main"),
            routes: {
              '/': (context) => const OnBoardingPage(),
              '/unlock': (context) => const AppLockPage(),
              '/setup-lock': (context) => const AppLockPage(setup: true),
              '/home': (context) => const HomePage(),
              '/main': (context) => const MainPage(),
            },
          );
        },
      ),
    );
  }
}
