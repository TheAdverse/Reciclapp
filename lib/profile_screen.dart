import 'package:flutter/material.dart';
import 'supabase_handler.dart';
import 'auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _cargarPreferencias();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _handler.getUserProfile();
      debugPrint("================= $data");
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("========== $e");
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
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: _mostrarAjustesGenerales,
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
                        _userData?['nombre_usuario'] ?? 'Usuario',
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
              subtitle: 'Nombre y usuario',
              onTap: _mostrarDialogoEdicion,
            ),
            _buildProfileOption(
              icon: Icons.notifications_none,
              title: 'Notificaciones',
              subtitle: 'Ajustes de alertas y avisos',
              onTap: _mostrarAjustesNotificaciones,
            ),
            _buildProfileOption(
              icon: Icons.lock_outline,
              title: 'Seguridad',
              subtitle: 'Cambiar contraseña',
              onTap: _mostrarDialogoCambiarPassword,
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

  void _mostrarDialogoEdicion() {
    // El controlador inicia con el nombre actual que ya tenemos en _userData
    final TextEditingController nombreController = 
        TextEditingController(text: _userData?['nombre_completo'] ?? '');
    final TextEditingController userController = 
        TextEditingController(text: _userData?['nombre_usuario'] ?? '');
    var nme = _userData?['nombre_completo'];
    var usr = _userData?['nombre_usuario'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Editar Datos Personales"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre Completo",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: "Nombre de Usuario",
                border: OutlineInputBorder(),
              ),
            ),
            const Text(
              "Se ignorarán los campos vacios.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (nombreController.text.trim().isNotEmpty){nme = nombreController.text.trim();}
              if (userController.text.trim().isNotEmpty){usr = userController.text.trim();}
              try {
                await _handler.actualizarPerfil(
                  nuevoNombre: nme,
                  nuevoUsuario: usr,
                );
                if (!context.mounted) return;
                if (mounted) {
                  Navigator.pop(context); // Cierra el diálogo
                  _loadProfile(); // Recarga los datos para que se vea el cambio
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Perfil actualizado correctamente"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Error al actualizar: $e");
              }
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _notifTips = true;
  bool _notifRacha = true;
  bool _notifComunidad = true;

  // 2. Carga los datos guardados en el dispositivo
  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifTips = prefs.getBool('notif_tips') ?? true;
      _notifRacha = prefs.getBool('notif_racha') ?? true;
      _notifComunidad = prefs.getBool('notif_comunidad') ?? true;
    });
  }

  // 3. Guarda los datos en el dispositivo
  Future<void> _guardarPreferencia(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // 4. Ventana Modal de Ajustes
  void _mostrarAjustesNotificaciones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Por si agregas más opciones después
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Configurar Notificaciones", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              
              // --- SECCIÓN DE TIPS ---
              SwitchListTile(
                title: const Text("Tips de Reciclaje"),
                subtitle: const Text("Consejos aleatorios cada día"),
                activeThumbColor: Colors.green,
                value: _notifTips,
                onChanged: (bool value) {
                  _guardarPreferencia('notif_tips', value);
                  setModalState(() => _notifTips = value);
                  setState(() {}); // Actualiza la UI de fondo si es necesario
                },
              ),

              // --- SECCIÓN DE RACHA ---
              SwitchListTile(
                title: const Text("Recordatorios de Racha"),
                subtitle: const Text("¡No pierdas tu progreso!"),
                activeThumbColor: Colors.green,
                value: _notifRacha,
                onChanged: (bool value) {
                  _guardarPreferencia('notif_racha', value);
                  setModalState(() => _notifRacha = value);
                  setState(() {});
                },
              ),

              // --- SECCIÓN DE COMUNIDAD (FIREBASE) ---
              SwitchListTile(
                title: const Text("Alertas de la Comunidad"),
                subtitle: const Text("Noticias importantes y eventos"),
                activeThumbColor: Colors.green,
                value: _notifComunidad,
                onChanged: (bool value) {
                  _guardarPreferencia('notif_comunidad', value);
                  setModalState(() => _notifComunidad = value);
                  setState(() {
                    if (value) {
                      FirebaseMessaging.instance.subscribeToTopic("alertas");
                    } else {
                      FirebaseMessaging.instance.unsubscribeFromTopic("alertas");
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }


  void _mostrarDialogoCambiarPassword() {
    final TextEditingController passController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    // Variables locales para el estado del "ojito"
    bool obscurePass = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // <--- Vital para que el setState funcione en el diálogo
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Seguridad"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView( // Por si el teclado estorba
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Ingresa tu nueva clave para Reciclapp:"),
                  const SizedBox(height: 20),
                  
                  // --- NUEVA CONTRASEÑA ---
                  TextFormField(
                    controller: passController,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // --- CONFIRMAR CONTRASEÑA ---
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value != passController.text ? 'No coinciden' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _handler.cambiarPassword(passController.text);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Contraseña actualizada correctamente"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    // Aquí puedes mostrar un error más específico
                  }
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }


  // Función para mostrar los ajustes
  void _mostrarAjustesGenerales() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Ajustes Generales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          
          // Información de la App
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.green),
            title: const Text("Versión de la App"),
            subtitle: const Text("v1.2.8 - Reciclapp"),
          ),

          // Limpiar Datos Locales
          ListTile(
            leading: const Icon(Icons.storage_outlined, color: Colors.orange),
            title: const Text("Limpiar datos locales"),
            subtitle: const Text("Restablece todas las preferencias a su estado original"),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              
              // Limpiamos todo el almacenamiento local
              await prefs.clear();

              // Si quieres ser muy estricto con Firebase al limpiar datos:
              await FirebaseMessaging.instance.unsubscribeFromTopic("alertas");

              if (!mounted) return;

              // Actualizamos nuestras variables de estado a los valores por defecto
              setState(() {
                _notifTips = true;
                _notifRacha = true;
                _notifComunidad = true;
              });

              Navigator.pop(context); // Cierra el modal

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Preferencias restablecidas correctamente"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          // Centro de Ayuda
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: const Text("Centro de Ayuda"),
            subtitle: const Text("Reportar problemas o sugerencias"),
            onTap: () {
              // Ejemplo: Podrías abrir un formulario de Google o mail de soporte
              // launchUrl(Uri.parse('mailto:soporte@reciclapp.com'));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

}