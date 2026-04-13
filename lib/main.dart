import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import 'tips.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:math';

// 1. Manejador de mensajes en SEGUNDO PLANO (App cerrada o minimizada)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Mensaje recibido en segundo plano: ${message.messageId}");
}

// 2. Dispatcher para tareas de Workmanager (Tips aleatorios)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final bool quiereTips = prefs.getBool('notif_tips') ?? true;

    _programarSiguienteTip();

    if (!quiereTips) return Future.value(true);

    FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(settings: const InitializationSettings(android: androidInit));

    final categorias = ['PET', 'ALUMINIO', 'CARTÓN', 'GENERICO'];
    final materialAzar = categorias[Random().nextInt(categorias.length)];
    String tipDelDia = RecyclingTips.obtenerTipAleatorio(materialAzar);

    await notifications.show(
      id: 100, // ID (este se puede quedar así)
      title: '¡Tip de Reciclapp! ♻️', // Título
      body: tipDelDia, // Cuerpo
      notificationDetails:  NotificationDetails( // Detalles
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Tips Diarios',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.green,
          styleInformation: BigTextStyleInformation(tipDelDia),
        ),
      ),
    );

    return Future.value(true);
  });
}

void _programarSiguienteTip() {
  int horasParaSiguiente = Random().nextInt(12) + 12;
  DateTime horaEstimada = DateTime.now().add(Duration(hours: horasParaSiguiente));
  
  if (horaEstimada.hour >= 23 || horaEstimada.hour <= 8) {
    horasParaSiguiente += 9; 
  }

  Workmanager().registerOneOffTask(
    "envio_tip_azar_${DateTime.now().millisecondsSinceEpoch}",
    "envio_tip_diario",
    initialDelay: Duration(hours: horasParaSiguiente),
    existingWorkPolicy: ExistingWorkPolicy.append,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de Firebase
  await Firebase.initializeApp();

  // Configurar el manejador de segundo plano para Firebase
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Inicializar Workmanager
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerOneOffTask(
    "primer_tip_inicio", 
    "envio_tip_diario",
    initialDelay: const Duration(minutes: 1),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // --- CONFIGURACIÓN DE NOTIFICACIONES LOCALES Y FIREBASE ---
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();

  try {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones de Reciclapp',
      description: 'Este canal se usa para tips y alertas de comunidad.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ESCUCHAR MENSAJES EN PRIMER PLANO (App abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // LEER PREFERENCIAS
      final prefs = await SharedPreferences.getInstance();
      final bool quiereComunidad = prefs.getBool('notif_comunidad') ?? true;

      // Si el usuario apagó las alertas de comunidad, ignoramos el mensaje
      if (!quiereComunidad) return;

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails:  NotificationDetails(   // Los Detalles
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notificaciones de Reciclapp',
              icon: '@mipmap/ic_launcher',
              color: Colors.green,
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(notification.body ?? ''),
            ),
          ),
        );
      }
    });

    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint("Token FCM: $token");
  } catch (e) {
    debugPrint("Error en notificaciones: $e");
  }

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
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.green)),
            );
          }
          final session = snapshot.hasData ? snapshot.data!.session : null;
          if (session != null) return const MainScreen(); 
          return const AuthScreen();
        },
      ),
    );
  }
}