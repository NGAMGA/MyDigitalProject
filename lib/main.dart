import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MealExplorerApp());
}

class MealExplorerApp extends StatelessWidget {
  const MealExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Meal Explorer',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4CAF7D),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF4FAF6),
              cardColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF4CAF7D),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFD8F5E3),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: selected
                        ? const Color(0xFF145C39)
                        : const Color(0xFF53645B),
                    size: selected ? 25 : 23,
                  );
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    color: selected
                        ? const Color(0xFF145C39)
                        : const Color(0xFF53645B),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  );
                }),
              ),
              fontFamily: 'Georgia',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6EE7A8),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF101915),
              cardColor: const Color(0xFF17231E),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF17231E),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              navigationBarTheme: const NavigationBarThemeData(
                backgroundColor: Color(0xFF17231E),
                indicatorColor: Color(0xFF275F42),
              ),
              fontFamily: 'Georgia',
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
