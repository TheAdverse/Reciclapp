import 'dart:math';

class RecyclingTips {
  static final Map<String, List<String>> _tips = {
    'PET': [
      "¡Buen trabajo! Recuerda aplastar la botella para que ocupe menos espacio.",
      "Tip: Quitar la etiqueta ayuda mucho en el proceso de reciclaje.",
      "¿Sabías que el PET se puede transformar en fibras para ropa? ¡Sigue así!",
      "Tip: Asegúrate de que la botella esté vacía y seca antes de depositarla.",
      "¡Dato curioso! Reciclar una sola botella de PET ahorra energía para iluminar un foco por 6 horas.",
      "Tip: No tires la tapa, ¡puedes juntarlas por separado para donaciones!",
      "¿Sabías que el PET tarda hasta 450 años en degradarse? ¡Gracias por reciclarlo!",
      "Tip: Si la botella es de aceite, lávala con un poco de jabón antes de reciclar.",
      "Dato: El PET reciclado se usa para hacer alfombras y piezas de autos.",
      "¡Súper! Al reciclar PET evitas que terminen en nuestros océanos.",
    ],
    'ALUMINIO': [
      "¡Genial! El aluminio se puede reciclar infinitamente sin perder calidad.",
      "Recuerda enjuagar la lata si tiene residuos de comida o azúcar.",
      "Tip: No es necesario aplastar las latas si las llevas a centros con máquinas automáticas.",
      "¡Impresionante! Una lata regresa a la tienda como una nueva en menos de 60 días.",
      "El reciclaje de aluminio ahorra el 95% de la energía necesaria para fabricar aluminio nuevo.",
      "Tip: Junta la anilla (la pestaña) con la lata para que no se pierda en el proceso.",
      "¿Sabías que el 75% del aluminio producido en la historia sigue en uso hoy?",
      "Reciclar una lata ahorra energía para escuchar música en tu celular por 28 horas.",
      "Dato: Las latas de aluminio son el envase más reciclado en todo el mundo.",
      "¡Sigue sumando! El aluminio reciclado reduce la minería de bauxita.",
    ],
    'CARTÓN': [
      "¡Súper! Asegúrate de que el cartón no tenga grasa o restos de pizza.",
      "Tip: Desarma las cajas para que el transporte sea más eficiente.",
      "El cartón reciclado ahorra muchísima agua en su fabricación.",
      "¿Sabías que una tonelada de papel reciclado salva 17 árboles adultos?",
      "Recuerda retirar cualquier cinta adhesiva o grapas grandes de tus cajas.",
      "Tip: El cartón corrugado es de los materiales más fáciles de reciclar.",
      "Dato: El cartón puede reciclarse de 5 a 7 veces antes de que las fibras se dañen.",
      "¡Bien hecho! Evita reciclar cartón que esté mojado, ya que daña las máquinas.",
      "¿Sabías que el cartón reciclado se usa para hacer cajas de huevos y tubos de papel?",
      "Tip: Si tiene partes plastificadas, intenta separarlas del cartón.",
    ],
    'TETRAPAK': [
      "¡Excelente! El Tetrapak es 100% reciclable; se separa en cartón, polietileno y aluminio.",
      "Tip: Escurre bien el envase y despliega las esquinas para aplanarlo.",
      "Con el Tetrapak reciclado se pueden fabricar láminas para techos y mobiliario.",
      "Recuerda depositar el envase con su tapa puesta para que no se pierda en el proceso.",
      "¿Sabías que el 75% de un envase de Tetrapak es cartón virgen de alta calidad?",
      "Tip: No necesitas lavar a fondo el envase, con un enjuague rápido basta.",
      "Dato: En México, el Tetrapak se transforma en 'polialuminio' para construcción.",
      "¡Increíble! Tus envases de leche pueden terminar siendo una mesa escolar.",
      "Tip: Aplastar el envase ayuda a reducir las emisiones de CO2 durante el transporte.",
      "¡Gracias por reciclar! El Tetrapak ahorra espacio en los rellenos sanitarios.",
    ],
    'VIDRIO': [
      "¡Perfecto! El vidrio es uno de los materiales más limpios para reciclar.",
      "Tip: No mezcles vidrio de botellas con cristales de ventanas o espejos, son diferentes.",
      "Reciclar vidrio reduce la contaminación del aire en un 20% respecto a fabricar vidrio nuevo.",
      "¿Sabías que el vidrio nunca pierde sus propiedades, sin importar cuántas veces se recicle?",
      "Tip: Quita las tapas metálicas de los frascos y recíclalas por separado como metal.",
      "Dato: El vidrio se separa por colores (verde, ámbar y transparente) para reciclar mejor.",
      "Reciclar una botella de vidrio ahorra energía para que funcione una laptop por 25 min.",
      "¡Súper! El vidrio es 100% natural y no desprende químicos al medio ambiente.",
      "Tip: Si un frasco está roto, envuélvelo en papel antes de ponerlo en el contenedor.",
      "Dato: Una botella de vidrio puede tardar un millón de años en descomponerse.",
    ],
    'GENERICO': [
      "¡Cada acción cuenta! Gracias por ayudar a mantener Pachuca limpia.",
      "¿Sabías que reciclar reduce la huella de carbono de tu ciudad?",
      "¡Eres un héroe ecológico! Sigue sumando puntos.",
      "Reciclar no es solo una acción, es preservar nuestro futuro en Hidalgo.",
      "Tip: Separa siempre tus residuos en casa para facilitar el trabajo de los recolectores.",
      "¡Sigue así! Estás ayudando a reducir la saturación de los rellenos sanitarios locales.",
      "Dato: El 80% de lo que tiramos a la basura podría ser reciclado o reutilizado.",
      "Tip: Comprar productos con menos empaque es el primer paso para ayudar al planeta.",
      "¿Sabías que el símbolo de las flechas se llama 'Círculo de Möbius'?",
      "¡Felicidades por tus puntos! Estás haciendo un cambio real hoy.",
    ],
  };

  static String obtenerTipAleatorio(String material) {
    String clave = material.toUpperCase();
    // Si no tenemos el material en la lista, usamos el genérico
    List<String> frases = _tips.containsKey(clave) ? _tips[clave]! : _tips['GENERICO']!;
    
    return frases[Random().nextInt(frases.length)];
  }
}