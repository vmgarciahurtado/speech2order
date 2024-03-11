// import 'package:fuzzy/fuzzy.dart';
// import 'package:speech2order/model.dart';

// /// Busca productos en la [productos] basados en las [palabrasClave].
// ///
// /// Si la primera palabra clave coincide con el patrón `^\[0-9\].*`, se realiza una búsqueda por código de barras.
// /// De lo contrario, se realiza una búsqueda difusa por título.
// ///
// /// En la búsqueda por título, se intenta encontrar coincidencias para la frase completa.
// /// Si no se encuentran coincidencias para la frase completa, se combinan los resultados para cada palabra clave individual con ponderación.
// ///
// /// Los títulos de los productos y las palabras clave se normalizan eliminando tildes y convirtiendo a minúsculas antes de la búsqueda.
// ///
// /// Devuelve una lista de [Speech2OrderProduct] que coinciden con las palabras clave, ordenados por relevancia.
// List<Speech2OrderProduct> searchProducts(
//     List<Speech2OrderProduct> productos, List<String> palabrasClave) {
//   bool searchByCode = RegExp(r'^[0-9]').hasMatch(palabrasClave.first);

//   // Normalize keywords and product titles
//   palabrasClave = palabrasClave
//       .map((palabra) => palabra
//           .trim()
//           .toLowerCase()
//           .replaceAll(RegExp(r'[áàâãäå]'), 'a')
//           .replaceAll(RegExp(r'[éèêë]'), 'e')
//           .replaceAll(RegExp(r'[íìîï]'), 'i')
//           .replaceAll(RegExp(r'[óòôõöø]'), 'o')
//           .replaceAll(RegExp(r'[úùûü]'), 'u'))
//       .toList();

//   productos = productos
//       .map((producto) => Speech2OrderProduct(
//           title: producto.title
//               .toLowerCase()
//               .replaceAll(RegExp(r'[áàâãäå]'), 'a')
//               .replaceAll(RegExp(r'[éèêë]'), 'e')
//               .replaceAll(RegExp(r'[íìîï]'), 'i')
//               .replaceAll(RegExp(r'[óòôõöø]'), 'o')
//               .replaceAll(RegExp(r'[úùûü]'), 'u'),
//           barCode: producto.barCode))
//       .toList();

//   if (searchByCode) {
//     if (palabrasClave.every((palabra) => RegExp(r'^\d+$').hasMatch(palabra))) {
//       return productos
//           .where((producto) => palabrasClave.any((ultimos4Digitos) =>
//               producto.barCode.toLowerCase().endsWith(ultimos4Digitos)))
//           .take(20)
//           .toList();
//     } else {
//       return [];
//     }
//   } else {
//     final fuse = Fuzzy(
//       productos.map((p) => p.title).toList(),
//       options: FuzzyOptions(
//         findAllMatches: true,
//         tokenize: true,
//         threshold: 0.3,
//       ),
//     );

//     // Search for the full phrase
//     final phraseResults = fuse.search(palabrasClave.join(' '))
//       ..sort((a, b) => b.score.compareTo(a.score));

//     // If there are matches for the full phrase, use those
//     if (phraseResults.isNotEmpty) {
//       return phraseResults
//           .map((result) => productos.firstWhere((p) => p.title == result.item))
//           .toList();
//     }

//     // Otherwise, combine results for individual keywords with weighted scores
//     final results = palabrasClave
//         .map((palabra) =>
//             fuse.search(palabra)..sort((a, b) => b.score.compareTo(a.score)))
//         .toList();

//     final combinedResults = <Map<Speech2OrderProduct, double>>[];
//     for (var product in productos) {
//       double totalScore = 0.0;
//       List<double> keywordScores = [];
//       for (var i = 0; i < palabrasClave.length; i++) {
//         final resultForKeyword = results[i]
//             .firstWhereOrNull((result) => result.item == product.title);
//         if (resultForKeyword != null) {
//           totalScore += resultForKeyword.score;
//           keywordScores.add(resultForKeyword.score);
//         }
//       }
//       if (totalScore > 0) {
//         // Give more weight to matches with all keywords
//         totalScore *= keywordScores.length / palabrasClave.length;
//         combinedResults.add({product: totalScore});
//       }
//     }

//     combinedResults.sort((a, b) => b.values.first.compareTo(a.values.first));

//     final topProducts =
//         combinedResults.take(20).map((result) => result.keys.first).toList();

//     if (topProducts.isNotEmpty) {
//       return topProducts;
//     } else {
//       return productos
//           .where((producto) => palabrasClave.every((palabra) => producto.title
//               .toLowerCase()
//               .replaceAll(RegExp(r'[áàâãäå]'), 'a')
//               .replaceAll(RegExp(r'[éèêë]'), 'e')
//               .replaceAll(RegExp(r'[íìîï]'), 'i')
//               .replaceAll(RegExp(r'[óòôõöø]'), 'o')
//               .replaceAll(RegExp(r'[úùûü]'), 'u')
//               .contains(palabra)))
//           .take(20)
//           .toList();
//     }
//   }
// }

// /// Extensión para la clase [List] que agrega un método [firstWhereOrNull].
// extension ListExtension<T> on List<T> {
//   /// Devuelve el primer elemento de la lista que cumple con la condición [test],
//   /// o `null` si no se encuentra ninguno.
//   T? firstWhereOrNull(bool Function(T) test) {
//     for (var item in this) {
//       if (test(item)) {
//         return item;
//       }
//     }
//     return null;
//   }
// }

import 'package:fuzzy/fuzzy.dart';
import 'package:speech2order/model.dart';

/// Busca productos en la [productos] basados en las [palabrasClave].
///
/// Si la primera palabra clave coincide con el patrón `^\[0-9\].*`, se realiza una búsqueda por código de barras.
/// De lo contrario, se realiza una búsqueda difusa por título.
///
/// En la búsqueda por título, se intenta encontrar coincidencias para la frase completa.
/// Si no se encuentran coincidencias para la frase completa, se realiza una búsqueda por frase parcial.
/// Si no se encuentran coincidencias para la frase parcial, se realiza una búsqueda por prefijos de cada palabra clave.
///
/// Los títulos de los productos y las palabras clave se normalizan eliminando tildes y convirtiendo a minúsculas antes de la búsqueda.
///
/// Devuelve una lista de [Speech2OrderProduct] que coinciden con las palabras clave, ordenados por relevancia.
List<Speech2OrderProduct> searchProducts(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
  bool searchByCode = RegExp(r'^[0-9]').hasMatch(palabrasClave.first);

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
          .take(20)
          .toList()
          .reversed
          .toList();
    }

    // Search for partial phrase
    final partialPhraseResults = fuse
        .search(palabrasClave.join(' ').split(' ').first)
      ..sort((a, b) => b.score.compareTo(a.score));

    // If there are matches for the partial phrase, use those
    if (partialPhraseResults.isNotEmpty) {
      return partialPhraseResults
          .map((result) => productos.firstWhere((p) => p.title == result.item))
          .take(20)
          .toList()
          .reversed
          .toList();
    }

    // Search for prefixes of each keyword
    final keywordResults = <Speech2OrderProduct>[];
    const minPrefixLength = 4;
    for (int i = palabrasClave.first.length - 1;
        i >= minPrefixLength - 1;
        i--) {
      final prefixResults = fuse.search(palabrasClave.first.substring(0, i + 1))
        ..sort((a, b) => b.score.compareTo(a.score));

      if (prefixResults.isNotEmpty) {
        keywordResults.addAll(prefixResults
            .map(
                (result) => productos.firstWhere((p) => p.title == result.item))
            .toList());
        break;
      }
    }

    if (keywordResults.isNotEmpty) {
      return keywordResults.take(20).toList();
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
        // Give more weight to matches with all keywords
        totalScore *= keywordScores.length / palabrasClave.length;
        combinedResults.add({product: totalScore});
      }
    }

    combinedResults.sort((a, b) => b.values.first.compareTo(a.values.first));

    final topProducts =
        combinedResults.take(20).map((result) => result.keys.first).toList();

    if (topProducts.isNotEmpty) {
      return topProducts;
    } else {
      return [];
    }
  }
}

/// Extensión para la clase [List] que agrega un método [firstWhereOrNull].
extension ListExtension<T> on List<T> {
  /// Devuelve el primer elemento de la lista que cumple con la condición [test],
  /// o `null` si no se encuentra ninguno.
  T? firstWhereOrNull(bool Function(T) test) {
    for (var item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
