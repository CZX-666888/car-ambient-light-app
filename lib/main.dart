import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/bluetooth_manager.dart';
import 'providers/light_controller.dart';
import 'screens/main_control_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 全球前20种语言支持
  static const List<Locale> supportedLocales = [
    Locale('en'), Locale('zh'), Locale('es'), Locale('ar'), Locale('hi'),
    Locale('bn'), Locale('pt'), Locale('ru'), Locale('ja'), Locale('de'),
    Locale('fr'), Locale('ko'), Locale('it'), Locale('vi'), Locale('tr'),
    Locale('fa'), Locale('th'), Locale('pl'), Locale('nl'), Locale('id'),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothManager()),
        ChangeNotifierProxyProvider<BluetoothManager, LightController>(
          create: (context) => LightController(
            bluetoothManager: context.read<BluetoothManager>(),
          ),
          update: (context, bluetoothManager, previous) =>
              previous ?? LightController(bluetoothManager: bluetoothManager),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          primaryColor: const Color(0xFF00E5FF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00E5FF),
            surface: Color(0xFF1A1A1A),
          ),
        ),
        // 国际化配置：系统语言不匹配时默认回退到英文
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        localeResolutionCallback: (locale, supportedLocales) {
          // 优先匹配系统语言，不匹配时默认英文
          if (locale != null) {
            for (final supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) {
                return supported;
              }
            }
          }
          return const Locale('en'); // 默认英文
        },
        home: const MainControlScreen(),
      ),
    );
  }
}
