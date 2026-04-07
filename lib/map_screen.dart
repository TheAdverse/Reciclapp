import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// BORRA el import de latlong2 que da error
// Si flutter_map ya incluye latlong internamente, usa este:
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final supabase = Supabase.instance.client;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadCentros(); // Cargamos los puntos al iniciar
  }

  Future<void> _loadCentros() async {
    try {
      final data = await supabase.from('centros_acopio').select();
      final List<dynamic> centros = data as List<dynamic>;

      setState(() {
        _markers = centros.map((centro) {
          return Marker(
            point: LatLng(centro['latitud'], centro['longitud']),
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showCentroInfo(centro),
              child: const Icon(Icons.location_on, color: Colors.green, size: 40),
            ),
          );
        }).toList();
      });
    } catch (e) {
      print("Error cargando puntos: $e");
    }
  }

  void _showCentroInfo(dynamic centro) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(centro['nombre'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Aceptan: ${centro['tipo_residuo']}"),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(20.1010, -98.7591), // Centro de Pachuca
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.reciclapp',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}