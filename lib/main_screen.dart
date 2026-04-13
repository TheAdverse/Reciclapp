import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'points_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _permisosListos = false;
  bool _estaPidiendo = false; // Nombre corregido

  // Declaramos la lista de páginas
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Inicializamos las páginas aquí para evitar errores de tipo
    _pages = [
      const PointsScreen(),
      const ScannerScreen(),
      const MapScreen(),
      const ProfileScreen(),
    ];

    // Pedir permisos justo después de que se renderice el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _solicitarPermisosIniciales();
    });
  }

  Future<void> _solicitarPermisosIniciales() async {
    // Usamos el nombre correcto de la variable: _estaPidiendo
    if (_estaPidiendo || _permisosListos) return;

    setState(() => _estaPidiendo = true);

    try {
      // Pedimos todo en un solo bloque para evitar el error de "request already running"
      await [
        Permission.camera,
        Permission.location,
        Permission.notification,
      ].request();

      if (mounted) {
        setState(() {
          _estaPidiendo = false;
          _permisosListos = true; 
        });
      }
    } catch (e) {
      debugPrint("Error al solicitar permisos: $e");
      if (mounted) {
        setState(() => _estaPidiendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga mientras se gestionan los permisos
    if (!_permisosListos) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 20),
              Text("Iniciando Reciclapp...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages, 
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10)
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.stars_rounded), label: 'Puntos'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Escanear'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Mapa'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}