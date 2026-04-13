import 'dart:math';

class RecyclingTips {
  static final Map<String, List<String>> _tips = {
    'PET': [
      "¡Buen trabajo! Recuerda aplastar la botella para que ocupe menos espacio.",
      "Tip: Quitar la etiqueta ayuda mucho en el proceso de reciclaje.",
      "¿Sabías que el PET se puede transformar en fibras para ropa? ¡Sigue así!",
    ],
    'ALUMINIO': [
      "¡Genial! El aluminio se puede reciclar infinitamente sin perder calidad.",
      "Recuerda enjuagar la lata si tiene residuos de comida o azúcar.",
      "Tip: No es necesario aplastar las latas si las llevas a centros con máquinas automáticas.",
    ],
    'CARTÓN': [
      "¡Súper! Asegúrate de que el cartón no tenga grasa o restos de pizza.",
      "Tip: Desarma las cajas para que el transporte sea más eficiente.",
      "El cartón reciclado ahorra muchísima agua en su fabricación.",
    ],
    'GENERICO': [
      "¡Cada acción cuenta! Gracias por ayudar a mantener Pachuca limpia.",
      "¿Sabías que reciclar reduce la huella de carbono de tu ciudad?",
      "¡Eres un héroe ecológico! Sigue sumando puntos.",
    ],
  };

  static String obtenerTipAleatorio(String material) {
    String clave = material.toUpperCase();
    // Si no tenemos el material en la lista, usamos el genérico
    List<String> frases = _tips.containsKey(clave) ? _tips[clave]! : _tips['GENERICO']!;
    
    return frases[Random().nextInt(frases.length)];
  }
}