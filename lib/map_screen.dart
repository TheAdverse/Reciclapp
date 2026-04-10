import 'dart:async';
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
  final MapController _mapController = MapController();
  
  // Estado del Mapa
  List<Marker> _centrosMarkers = [];
  LatLng? _ubicacionUsuario;
  dynamic _centroSeleccionado;
  
  // Control de Streams
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _fetchCentros();           // Trae los puntos de Pachuca desde Supabase
    _configurarSeguimiento();  // Inicia el GPS en tiempo real
  }

  @override
  void dispose() {
    // Cerramos el stream al salir para ahorrar batería
    _positionStream?.cancel();
    super.dispose();
  }

  // --- LÓGICA DE UBICACIÓN ---

  Future<void> _configurarSeguimiento() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el GPS está activo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Gestionar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Configurar el Stream (Se activa cada 5 metros)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, 
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _ubicacionUsuario = LatLng(position.latitude, position.longitude);
        });
      }
    });

    // Obtener posición inicial para centrar el mapa al abrir
    try {
      Position initialPos = await Geolocator.getCurrentPosition();
      if (mounted) {
        _mapController.move(LatLng(initialPos.latitude, initialPos.longitude), 14);
      }
    } catch (e) {
      debugPrint("Error obteniendo posición inicial: $e");
    }
  }

  // --- LÓGICA DE DATOS (SUPABASE) ---

  Future<void> _fetchCentros() async {
    try {
      final data = await supabase.from('centros_acopio').select();
      final List<dynamic> centros = data as List<dynamic>;

      if (mounted) {
        setState(() {
          _centrosMarkers = centros.map((centro) {
            return Marker(
              point: LatLng(centro['latitud'], centro['longitud']),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => setState(() => _centroSeleccionado = centro),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 45,
                ),
              ),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error al cargar centros: $e");
    }
  }

  // --- DISEÑO DE INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Centros de Reciclaje",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        elevation: 4,
      ),
      body: Stack(
        children: [
          // Capa 1: El Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.1010, -98.7591), // Centro de Pachuca
              initialZoom: 13,
              onTap: (_, _) => setState(() => _centroSeleccionado = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.reciclapp',
              ),
              MarkerLayer(
                markers: [
                  ..._centrosMarkers, // Marcadores de la BD
                  if (_ubicacionUsuario != null)
                    Marker(
                      point: _ubicacionUsuario!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 35,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Capa 2: Panel de Información inferior
          if (_centroSeleccionado != null)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: _buildInfoCard(),
            ),
            
          // Botón flotante para centrar ubicación
          Positioned(
            bottom: _centroSeleccionado != null ? 220 : 20,
            right: 15,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (_ubicacionUsuario != null) {
                  _mapController.move(_ubicacionUsuario!, 15);
                }
              },
              child: const Icon(Icons.gps_fixed, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _centroSeleccionado['nombre'] ?? "Sin nombre",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _centroSeleccionado = null),
                ),
              ],
            ),
            const Divider(),
            _infoRow(Icons.eco, "Reciben: ${_centroSeleccionado['tipo_residuo']}"),
            const SizedBox(height: 8),
            _infoRow(Icons.location_pin, _centroSeleccionado['direccion'] ?? "Pachuca, Hgo."),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}