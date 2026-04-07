import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cargamos el archivo .env
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reciclapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // En tu main.dart
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // 1. Mientras revisa si hay sesión, mostramos un círculo de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.green)),
            );
          }

          // 2. Si hay una sesión activa, mandamos directo al MainScreen (Home)
          final session = snapshot.hasData ? snapshot.data!.session : null;
          if (session != null) {
            return const MainScreen(); 
          }

          // 3. Si no hay sesión, mandamos al Login
          return const AuthScreen();
        },
      ),
    );
  }
}