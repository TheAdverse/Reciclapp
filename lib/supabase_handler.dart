import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class SupabaseHandler {
  final SupabaseClient supabase = Supabase.instance.client;

  // --- AUTH & PERFIL ---

  Future<void> signUpUser({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String username,
  }) async {
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final String? userId = res.user?.id;

    if (userId != null) {
      await supabase.from('usuario').insert({
        'id_usuario': userId,
        'nombre_completo': '$nombre $apellido',
        'nombre_usuario': username,
        'puntos': 0,
        'premium': false, // Optimización: usar booleano real si tu columna lo permite
      });
    }
  }

  Future<void> signInUser(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      throw error.message; 
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // OPTIMIZACIÓN: Función única para la PointsScreen (Nombre + Puntos)
  Future<Map<String, dynamic>> obtenerDatosPerfil() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'nombre': 'Usuario', 'puntos': 0};

    try {
      final data = await supabase
          .from('usuario')
          .select('nombre_completo, puntos')
          .eq('id_usuario', user.id)
          .single();
      
      return {
        'nombre': data['nombre_completo'] ?? 'Usuario',
        'puntos': data['puntos'] ?? 0,
      };
    } catch (e) {
      return {'nombre': 'Usuario', 'puntos': 0};
    }
  }

  // Mantenemos esta por si la usas en otra parte
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      return await supabase
          .from('usuario')
          .select()
          .eq('id_usuario', user.id)
          .single();
    }
    return null;
  }

  Future<void> actualizarPerfil({
    required String nuevoNombre,
    required String nuevoUsuario
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('usuario')
        .update({
          'nombre_completo': nuevoNombre,
          'nombre_usuario': nuevoUsuario,
        })
        .eq('id_usuario', user.id);
  }

  Future<void> cambiarPassword(String nuevaPassword) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: nuevaPassword),
      );
    } catch (e) {
      throw Exception('Error al actualizar la contraseña: $e');
    }
  }

  // --- LÓGICA DE RECICLAJE ---

  Future<Map<String, dynamic>?> registrarReciclaje(String code) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final hace24Horas = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

    // 1. Validar si ya escaneó este código hoy
    final registroExistente = await supabase
        .from('registro_escaneo')
        .select()
        .eq('id_usuario', userId)
        .eq('codigo_barras', code)
        .gt('fecha_hora', hace24Horas)
        .maybeSingle();

    if (registroExistente != null) {
      return registroExistente; // Retornamos el registro previo para identificar el error
    }

    // 2. Buscar producto
    final producto = await supabase
        .from('reciclable')
        .select()
        .eq('codigo_barras', code)
        .maybeSingle();

    if (producto == null) return null;

    // 3. Insertar nuevo registro
    await supabase.from('registro_escaneo').insert({
      'id_usuario': userId,
      'codigo_barras': code,
      'puntos_obtenidos': producto['puntos_recompensa'], // Asegúrate que en la DB se llame puntos_obtenidos
      'fecha_hora': DateTime.now().toIso8601String(),
    });
    
    return producto;
  }

  Future<List<dynamic>> obtenerHistorialEscaneos() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    return await supabase
        .from('registro_escaneo')
        .select('*, reciclable(nombre_producto, tipo_material)')
        .eq('id_usuario', userId)
        .order('fecha_hora', ascending: false)
        .limit(15);
  }

  Future<bool> tieneInternet() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    // Si llegamos aquí, los datos o wifi están prendidos. 
    // Ahora verificamos si realmente hay navegación (saldo/señal).
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Hay internet real
      }
    } on SocketException catch (_) {
      return false; // Están prendidos los datos pero no hay internet (sin saldo)
    }
    
    return false;
  }
}