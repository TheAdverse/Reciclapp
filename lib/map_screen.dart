import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final supabase = Supabase.instance.client;
  List<Marker> _markers = [];
  dynamic _centroSeleccionado; // Para guardar el centro que tocamos
  final MapController _mapController = MapController(); // Para mover el mapa por código
  LatLng? _ubicacionUsuario; // Variable para guardar tu posición

  @override
  void initState() {
    super.initState();
    _fetchCentros(); // Carga los datos de Pachuca al iniciar
    _obtenerUbicacionActual(); // Llamada al GPS
  }

  Future<void> _obtenerUbicacionActual() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // Verificar si el GPS está encendido
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }

    // Obtener la posición actual
    Position position = await Geolocator.getCurrentPosition();
    
    setState(() {
      _ubicacionUsuario = LatLng(position.latitude, position.longitude);
      
      // Movemos la cámara del mapa a tu ubicación
      _mapController.move(_ubicacionUsuario!, 15); 
      
      // Agregamos un marcador azul para el usuario
      _markers.add(
        Marker(
          point: _ubicacionUsuario!,
          width: 60,
          height: 60,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    });
  }

  // Función para traer datos de Supabase
  Future<void> _fetchCentros() async {
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
              onTap: () {
                setState(() {
                  _centroSeleccionado = centro; // Guardamos los datos del punto
                });
              },
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 45,
              ),
            ),
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("Error al cargar centros: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Centros de Reciclaje",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true, // Esto centra el título, se ve muy bien en Android e iOS
        elevation: 2,      // Le da una pequeña sombra para separarla del mapa
      ),
      body: Stack(
        children: [
          // Capa 1: El Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.1010, -98.7591), // Pachuca
              initialZoom: 13,
              onTap: (_, _) {
                // Si tocas cualquier otra parte del mapa, se cierra el panel
                setState(() => _centroSeleccionado = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // Añade esta línea con el nombre de tu paquete (el que está en tu pubspec o AndroidManifest)
                userAgentPackageName: 'com.example.reciclapp', 
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Capa 2: Panel de Información (Solo si hay selección)
          if (_centroSeleccionado != null)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: _buildInfoCard(),
            ),
        ],
      ),
    );
  }

  // Widget del recuadro de información
  Widget _buildInfoCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _centroSeleccionado['nombre'],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _centroSeleccionado = null),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Aceptan: ${_centroSeleccionado['tipo_residuo']}",
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.redAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _centroSeleccionado['direccion'] ?? "Pachuca, Hidalgo",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}