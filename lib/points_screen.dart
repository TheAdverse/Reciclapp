import 'package:flutter/material.dart';
import 'supabase_handler.dart';
import 'dart:async';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final SupabaseHandler _handler = SupabaseHandler();
  
  bool _isLoading = true;
  String _nombreUsuario = "Usuario";
  int _puntosTotales = 0;
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos(); 
    });
  }

  Future<void> _cargarDatos() async {
    bool hayRed = await _handler.tieneInternet();
    if (!hayRed) {
      _mostrarBloqueoSinInternet();
      return; // No deja que el código avance a Supabase
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final perfil = await _handler.obtenerDatosPerfil();
      final historial = await _handler.obtenerHistorialEscaneos();

      if (mounted) {
        setState(() {
          _nombreUsuario = perfil['nombre'];
          _puntosTotales = perfil['puntos'];
          _historial = historial;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando PointsScreen: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE ICONOS DINÁMICOS POR MATERIAL ---
  IconData _getIconoMaterial(String material) {
    String m = material.toLowerCase();
    if (m.contains('pet') || m.contains('plastico') || m.contains('plástico')) {
      return Icons.local_drink_rounded; 
    } else if (m.contains('aluminio') || m.contains('metal') || m.contains('lata')) {
      return Icons.view_in_ar_rounded; 
    } else if (m.contains('vidrio')) {
      return Icons.wine_bar_rounded;
    } else if (m.contains('papel') || m.contains('carton') || m.contains('cartón')) {
      return Icons.auto_stories_rounded; 
    }
    return Icons.inventory_2_outlined; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // APPBAR SIN TEXTO: Solo acciones para un look ultra limpio
      appBar: AppBar(
        title: const Text('Mis Puntos'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 28),
              onPressed: _cargarDatos,
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: Colors.green[700],
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // --- SALUDO ---
                  Text(
                    "¡Hola, $_nombreUsuario!",
                    style: const TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87,
                      letterSpacing: -0.5
                    ),
                  ),
                  const Text(
                    "Este es tu progreso actual en Reciclapp.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 25),

                  // --- TARJETA DE PUNTOS ---
                  _buildTarjetaPuntos(),

                  const SizedBox(height: 35),

                  // --- HISTORIAL ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Historial de Reciclaje",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {}, 
                        child: Text("Ver todo", style: TextStyle(color: Colors.green[700])),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  _historial.isEmpty
                      ? _buildEstadoVacio()
                      : _buildListaHistorial(),
                ],
              ),
            ),
    );
  }

  Widget _buildTarjetaPuntos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[800]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.eco_rounded, color: Colors.white, size: 45),
          const SizedBox(height: 10),
          const Text(
            "PUNTOS ACUMULADOS",
            style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            "$_puntosTotales",
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 60, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "¡Sigue así, estás ayudando al planeta!",
            style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildListaHistorial() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final item = _historial[index];
        final producto = item['reciclable'];
        final String material = producto['tipo_material'] ?? "Reciclable";
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconoMaterial(material), 
                color: Colors.green[700]
              ),
            ),
            title: Text(
              producto['nombre_producto'] ?? "Producto",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  material.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11, 
                    color: Colors.green[700], 
                    fontWeight: FontWeight.w800
                  ),
                ),
                Text(
                  item['fecha_hora'].toString().substring(0, 10),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Text(
              "+${item['puntos_obtenidos']} pts",
              style: const TextStyle(
                color: Colors.blueAccent, 
                fontWeight: FontWeight.bold, 
                fontSize: 17
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoVacio() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.history_rounded, size: 60, color: Colors.grey[200]),
        const SizedBox(height: 10),
        const Text("No hay registros aún", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  void _mostrarBloqueoSinInternet() {
    // Creamos un timer que cheque la conexión cada 3 segundos
    Timer? timer;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Iniciamos el timer cuando se construye el diálogo
        timer = Timer.periodic(const Duration(seconds: 3), (t) async {
          bool conectado = await _handler.tieneInternet();
          if (conectado) {
            t.cancel(); // Detenemos el timer
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Quitamos el mensaje automáticamente
            }
          }
        });

        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Colors.orange, size: 50),
                SizedBox(height: 10),
                Text("Conexión Inestable", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "Detectamos que no tienes saldo o señal suficiente.\n\nEl mensaje se quitará solo cuando recuperes tu conexión.",
              textAlign: TextAlign.center,
            ),
            // Quitamos los botones para que sea puramente automático
          ),
        );
      },
    ).then((_) => timer?.cancel()); // Por seguridad, cancelamos el timer si el diálogo se cierra
  }
}