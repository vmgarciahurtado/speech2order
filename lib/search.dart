import 'package:fuzzy/fuzzy.dart';
import 'package:speech2order/model.dart';

List<Speech2OrderProduct> searchProducts(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
  bool searchByCode = RegExp(r'^[0-9].*').hasMatch(palabrasClave.first);
  // Normalize keywords and product titles
  palabrasClave = palabrasClave
      .map((palabra) => palabra
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[áàâãäå]'), 'a')
          .replaceAll(RegExp(r'[éèêë]'), 'e')
          .replaceAll(RegExp(r'[íìîï]'), 'i')
          .replaceAll(RegExp(r'[óòôõöø]'), 'o')
          .replaceAll(RegExp(r'[úùûü]'), 'u'))
      .toList();

  productos = productos
      .map((producto) => Speech2OrderProduct(
          title: producto.title
              .toLowerCase()
              .replaceAll(RegExp(r'[áàâãäå]'), 'a')
              .replaceAll(RegExp(r'[éèêë]'), 'e')
              .replaceAll(RegExp(r'[íìîï]'), 'i')
              .replaceAll(RegExp(r'[óòôõöø]'), 'o')
              .replaceAll(RegExp(r'[úùûü]'), 'u'),
          barCode: producto.barCode))
      .toList();

  if (searchByCode) {
    if (palabrasClave.every((palabra) => RegExp(r'^\d+$').hasMatch(palabra))) {
      return productos
          .where((producto) => palabrasClave.any((ultimos4Digitos) =>
              producto.barCode.toLowerCase().endsWith(ultimos4Digitos)))
          .take(20)
          .toList();
    } else {
      return [];
    }
  } else {
    final fuse = Fuzzy(
      productos.map((p) => p.title).toList(),
      options: FuzzyOptions(
        findAllMatches: true,
        tokenize: true,
        threshold: 0.3,
      ),
    );

    // Search for the full phrase
    final phraseResults = fuse.search(palabrasClave.join(' '))
      ..sort((a, b) => b.score.compareTo(a.score));

    // If there are matches for the full phrase, use those
    if (phraseResults.isNotEmpty) {
      return phraseResults
          .map((result) => productos.firstWhere((p) => p.title == result.item))
          .toList();
    }

    // Otherwise, combine results for individual keywords with weighted scores
    final results = palabrasClave
        .map((palabra) =>
            fuse.search(palabra)..sort((a, b) => b.score.compareTo(a.score)))
        .toList();

    final combinedResults = <Map<Speech2OrderProduct, double>>[];
    for (var product in productos) {
      double totalScore = 0.0;
      List<double> keywordScores = [];
      for (var i = 0; i < palabrasClave.length; i++) {
        final resultForKeyword = results[i]
            .firstWhereOrNull((result) => result.item == product.title);
        if (resultForKeyword != null) {
          totalScore += resultForKeyword.score;
          keywordScores.add(resultForKeyword.score);
        }
      }
      if (totalScore > 0) {
        // Dar más peso a las coincidencias con todas las palabras clave
        totalScore *= keywordScores.length / palabrasClave.length;
        combinedResults.add({product: totalScore});
      }
    }

    combinedResults.sort((a, b) => b.values.first.compareTo(a.values.first));

    final topProducts =
        combinedResults.take(20).map((result) => result.keys.first).toList();

    return topProducts;
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
