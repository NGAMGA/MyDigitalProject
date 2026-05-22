import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/favorites_provider.dart';
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
    return ChangeNotifierProvider<FavoritesProvider>(
      create: (_) => FavoritesProvider(),
      child: MaterialApp(
        title: 'Meal Explorer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF7D),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4FAF6),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4CAF7D),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          fontFamily: 'Georgia',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
