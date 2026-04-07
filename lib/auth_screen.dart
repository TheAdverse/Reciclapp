import 'package:flutter/material.dart';
import 'supabase_handler.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseHandler _handler = SupabaseHandler(); // Instancia del manejador
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false; // Para mostrar un indicador de carga

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _getFriendlyErrorMessage(String technicalError) {
  // Errores de Inicio de Sesión
  if (technicalError.contains('Invalid login credentials')) {
    return 'El correo o la contraseña son incorrectos. Verifica tus datos.';
  }
  
  // Errores de Registro
  if (technicalError.contains('User already registered')) {
    return 'Este correo ya tiene una cuenta activa. Intenta iniciar sesión.';
  }
  
  if (technicalError.contains('Password should be at least 6 characters')) {
    return 'La contraseña es muy corta. Usa al menos 6 caracteres.';
  }

  if (technicalError.contains('network')) {
    return 'Parece que no tienes internet. Revisa tu conexión.';
  }

  // Error por defecto si no conocemos el mensaje
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          await _handler.signInUser(_emailController.text, _passwordController.text);
          // Dentro de if (_isLogin) despues del await _handler.signInUser...
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("¡Bienvenido!", textAlign: TextAlign.center,),
              backgroundColor: Colors.green[400],
              behavior: SnackBarBehavior.floating, // Se ve más moderno, como tu diseño
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          await _handler.signUpUser(
            email: _emailController.text,
            password: _passwordController.text,
            nombre: _nameController.text,
            apellido: _lastNameController.text,
            username: _usernameController.text,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Registro exitoso. Inicia Sesión.", textAlign: TextAlign.center,),
              backgroundColor: Colors.green[400],
              behavior: SnackBarBehavior.floating, // Se ve más moderno, como tu diseño
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() { _isLogin = !_isLogin; _formKey.currentState?.reset();});
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          
          final friendlyMsg = _getFriendlyErrorMessage(e.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyMsg),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _isLogin ? Icons.recycling : Icons.person_add_alt_1,
                  size: 80,
                  color: Colors.green[700],
                ),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Bienvenido a Reciclapp' : 'Únete a Reciclapp',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
                const SizedBox(height: 32),
                
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Ingresa tus apellidos' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Usuario', prefixIcon: Icon(Icons.account_circle), border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Ingresa un nombre de usuario' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Ingresa un correo válido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),

                _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
                    ),
                
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _formKey.currentState?.reset();
                  }),
                  child: Text(_isLogin ? '¿No tienes cuenta? Regístrate aquí' : '¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: Colors.green[800])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}