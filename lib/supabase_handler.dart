import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHandler {
  final SupabaseClient supabase = Supabase.instance.client;

  // Función para Registro
  Future<void> signUpUser({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String username,
  }) async {
    // 1. Crear usuario en Auth
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final String? userId = res.user?.id;

    // 2. Insertar datos adicionales en la tabla 'usuario'
    if (userId != null) {
      await supabase.from('usuario').insert({
        'id_usuario': userId,
        'nombre_completo': '$nombre $apellido',
        'nombre_usuario': username,
        'puntos': 0,
        'premium': 'false',
      });
    }
  }

  // Función para Login
  Future<void> signInUser(String email, String password) async {
  try {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  } on AuthException catch (error) {
    // Re-lanzamos el error para que el UI lo atrape
    throw error.message; 
  }
}

  // Cerrar sesión
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Obtener datos del perfil del usuario actual
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase
          .from('usuario')
          .select()
          .eq('id_usuario', user.id)
          .single();
      return data;
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

}