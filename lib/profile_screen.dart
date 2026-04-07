import 'package:flutter/material.dart';
import 'supabase_handler.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseHandler _handler = SupabaseHandler();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _handler.getUserProfile();
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () { /* Navegar a ajustes generales */ },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Cabecera del Perfil (Basado en Imagen 4)
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.person, size: 50, color: Colors.green),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userData?['nombre_completo'] ?? 'Usuario',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _handler.supabase.auth.currentUser?.email ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // 2. Opciones de Gestión
            _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Datos personales',
              subtitle: 'Nombre, usuario y correo',
              onTap: () { /* Abrir formulario de edición */ },
            ),
            _buildProfileOption(
              icon: Icons.notifications_none,
              title: 'Notificaciones',
              subtitle: 'Ajustes de alertas y avisos',
              onTap: () { /* Ajustes de notificaciones */ },
            ),
            _buildProfileOption(
              icon: Icons.lock_outline,
              title: 'Seguridad',
              subtitle: 'Cambiar contraseña',
              onTap: () { /* Lógica de cambio de clave */ },
            ),
            _buildProfileOption(
              icon: Icons.settings_outlined,
              title: 'Preferencias',
              subtitle: 'Idioma y personalización',
              onTap: () { /* Otros ajustes */ },
            ),
            
            const SizedBox(height: 30),
            
            // Botón de Cerrar Sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                // Botón de Cerrar Sesión
                onPressed: () async {
                  try {
                    await _handler.signOut();

                    // Esta es la forma técnica correcta que pide el editor:
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("¡Hasta luego! Vuelve pronto",textAlign: TextAlign.center,),
                      backgroundColor: Colors.green[400],
                      behavior: SnackBarBehavior.floating, // Se ve más moderno, como tu diseño
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  } catch (e) {
                    debugPrint("Error al cerrar sesión: $e");
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}