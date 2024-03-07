import 'package:speech2order/constants/numbers.dart';
import 'package:speech2order/constants/unit_measure.dart';
import 'package:speech2order/constants/unit_volume.dart';

List<String> processWords(String text) {
  final words = text.split(' ');

  for (int i = 0; i < words.length; i++) {
    for (int j = words.length; j >= i + 1; j--) {
      final combinacion = words.sublist(i, j).join(' ');
      if (numbersByTextName.containsKey(combinacion)) {
        words.replaceRange(i, j, [numbersByTextName[combinacion].toString()]);
        break; // Salimos del bucle interior una vez que se encuentra una coincidencia
      }
    }
  }

  List<String> result = groupNumbers(words);

  for (int i = 0; i < result.length; i++) {
    if ((result[i] == 'por' || result[i] == '*') && result.length > i + 1) {
      final numero = result[i + 1];
      if (RegExp(r'^\d+$').hasMatch(numero)) {
        result.replaceRange(i, i + 2, ['x$numero']);
      }
    }
  }

  return result;
}

String processUnitMeasure(String text) {
  String newText = text;
  unitVolume.forEach((key, value) {
    final pattern = RegExp(r'\b$key\b', caseSensitive: false);
    newText = newText.replaceAllMapped(pattern, (match) => value);
  });
  return newText;
}

String processUnitVolume(String text) {
  String newText = text;
  unitMeasure.forEach((key, value) {
    final pattern = RegExp(r'\b$key\b', caseSensitive: false);
    newText = newText.replaceAllMapped(pattern, (match) => value);
  });
  return newText;
}

int processProductQuantity(List<String> words) {
  // Verificar si alguna palabra contiene una cantidad directa o un formato 'x25'
  if (words.any((word) => RegExp(r'^x\d+$').hasMatch(word))) {
    // Buscar el formato 'x25' y devolver la cantidad
    final xFormat = words.firstWhere((word) => RegExp(r'^x\d+$').hasMatch(word),
        orElse: () => '');
    if (xFormat.isNotEmpty) {
      return int.parse(xFormat.substring(1));
    }
  }

  return 1;
}

List<String> removeProductQuantity(List<String> words) {
  final regex = RegExp(r'^x\d+$');
  return words
      .map((word) => word.replaceFirst(regex, ''))
      .where((element) => element.isNotEmpty)
      .toList();
}

List<String> groupNumbers(List<String> palabras) {
  List<String> result = [];
  String currentNumber = '';

  for (String palabra in palabras) {
    if (RegExp(r'^\d+$').hasMatch(palabra)) {
      currentNumber += palabra;
    } else {
      if (currentNumber.isNotEmpty) {
        result.add(currentNumber);
        currentNumber = '';
      }
      result.add(palabra);
    }
  }

  if (currentNumber.isNotEmpty) {
    result.add(currentNumber);
  }

  return result;
}
