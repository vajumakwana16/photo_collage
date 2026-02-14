import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/collage_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CollageProvider()),
      ],
      child: const PhotoCollageApp(),
    ),
  );
}

class PhotoCollageApp extends StatelessWidget {
  const PhotoCollageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Collage Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData( 
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed( 
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
