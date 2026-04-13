import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'supabase_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tips.dart';
import 'package:flutter/services.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(autoStart: true);
  final SupabaseHandler _handler = SupabaseHandler();
  
  bool _escaneado = false;      
  bool _buscandoCodigo = false; 
  Timer? _timerScan;     


  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _revisarYEncender();
  }

  Future<void> _revisarYEncender() async {
    if (!mounted) return;

    var status = await Permission.camera.status;
    
    if (status.isGranted) {
      try {
        // USAMOS .value EN AMBOS:
        // Solo intentamos arrancar si NO está iniciando Y NO está ya inicializado
        if (!_controller.value.isStarting && !_controller.value.isInitialized) {
          await _controller.start();
          if (mounted) setState(() {});
          debugPrint("✅ Cámara iniciada con éxito");
        }
      } catch (e) {
        // Este catch evita que la app se detenga si hay un choque de estados
        debugPrint("Cámara en transición o ya lista: $e");
      }
    } else {
      debugPrint("⚠️ Esperando permisos de cámara...");
    }
  } 

  @override
  void deactivate() {
    _controller.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _timerScan?.cancel();
    _controller.stop(); 
    _controller.dispose(); 
    super.dispose();
  }

  void _iniciarEscaneo() {
    if (_buscandoCodigo) return;

    setState(() {
      _buscandoCodigo = true;
      _escaneado = false;
    });

    _timerScan?.cancel();
    _timerScan = Timer(const Duration(seconds: 10), () {
      if (mounted && _buscandoCodigo && !_escaneado) {
        setState(() => _buscandoCodigo = false);
        _mostrarMensaje("Tiempo agotado", "No se detectó ningún código. Intenta de nuevo.");
      }
    });
  }

  void _procesarCodigo(String? code) async {
    if (code == null || _escaneado) return;
    HapticFeedback.mediumImpact();
    
    _timerScan?.cancel();
    setState(() {
      _escaneado = true;
      _buscandoCodigo = false;
    });

    final resultado = await _handler.registrarReciclaje(code);

    if (!mounted) return;

    if (resultado != null) {
      if (resultado["id_escaneo"] != null) {
        _mostrarMensaje("Producto ya registrado", "Este código ya fue registrado por ti hoy. Intenta en 24 horas.");
      } else {
        _mostrarExitoModal(
          resultado['nombre_producto'] ?? "Producto", 
          resultado['puntos_recompensa'] ?? 0,
          resultado['tipo_material'] ?? "Reciclable"
        );
      }
    } else {
      _mostrarMensaje("No encontrado", "Este código no está registrado en el catálogo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro para resaltar la cámara
      appBar: AppBar(
        title: const Text("Escanear Producto"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, child) {
              IconData icon;
              Color color;
              switch (value.torchState) {
                case TorchState.off: icon = Icons.flash_off; color = Colors.white54; break;
                case TorchState.on: icon = Icons.flash_on; color = Colors.yellow; break;
                case TorchState.auto: icon = Icons.flash_auto; color = Colors.blue; break;
                case TorchState.unavailable: icon = Icons.flash_off; color = Colors.red.withValues(alpha:0.3); break;
              }
              return IconButton(icon: Icon(icon, color: color), onPressed: () => _controller.toggleTorch());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            scanWindow: Rect.fromCenter(
              center: Offset(
                MediaQuery.of(context).size.width / 2,
                MediaQuery.of(context).size.height / 2 - 20, // Ajuste ligero por el AppBar
              ),
              width: 250,
              height: 250,
            ),
            onDetect: (capture) {
              if (!_buscandoCodigo || _escaneado || !mounted) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) _procesarCodigo(code);
              }
            },
          ),
          _buildOverlay(),
          if (_buscandoCodigo)
            const Positioned(
              bottom: 120, left: 0, right: 0,
              child: Center(
                child: Chip(
                  label: Text("Buscando código...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _buscandoCodigo ? null : _iniciarEscaneo,
        backgroundColor: _buscandoCodigo ? Colors.grey : Colors.green[800],
        icon: Icon(_buscandoCodigo ? Icons.hourglass_empty : Icons.qr_code_scanner, color: Colors.white),
        label: Text(
          _buscandoCodigo ? "Escaneando..." : "Presiona para Escanear",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.transparent)),
              Center(
                child: Container(
                  height: 250, width: 250,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: _buscandoCodigo ? Colors.greenAccent : Colors.white24, width: 4), 
              borderRadius: BorderRadius.circular(30)
            ),
          ),
        ),
      ],
    );
  }

  // --- MODAL DE ÉXITO CON CONSEJOS DINÁMICOS ---

  void _mostrarExitoModal(String nombre, int puntos, String material) {
    // Obtenemos el consejo aleatorio antes de mostrar el modal
    final String consejoAleatorio = RecyclingTips.obtenerTipAleatorio(material);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      // isScrollControlled: true es CLAVE para evitar el overflow en BottomSheets
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30))
      ),
      builder: (context) => Padding(
        // Este padding asegura que el pop-up no quede detrás del teclado o barras del sistema
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
                const SizedBox(height: 15),
                Text(
                  nombre, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    material.toUpperCase(),
                    style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "+$puntos Puntos", 
                  style: const TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.bold)
                ),
                const Text(
                  "Bonificación aplicada correctamente", 
                  style: TextStyle(color: Colors.grey, fontSize: 14)
                ),
                
                const SizedBox(height: 25),

                // --- SECCIÓN DE TIP ECOLÓGICO ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          consejoAleatorio,
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () { 
                      Navigator.pop(context); 
                      setState(() {
                        _escaneado = false;
                        _buscandoCodigo = false;
                      });
                    },
                    child: const Text("Continuar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarMensaje(String titulo, String mensaje) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _escaneado = false;
                _buscandoCodigo = false;
              });
            },
            child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}