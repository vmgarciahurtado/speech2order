import 'package:fuzzy/fuzzy.dart';
import 'package:speech2order/model.dart';

List<Speech2OrderProduct> searchProducts(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
  // ... (Normalization code remains the same)

  // Create Fuzzy instances for both title and barcode
  final fuseTitle = Fuzzy(
    productos.map((p) => p.title).toList(),
    options: FuzzyOptions(
      findAllMatches: true,
      tokenize: true,
      threshold: 0.5, // Adjust threshold as needed
    ),
  );
  final fuseBarCode = Fuzzy(
    productos.map((p) => p.barCode).toList(),
    options: FuzzyOptions(
      findAllMatches: true,
      tokenize: true,
      threshold: 0.8, // Potentially higher threshold for barcodes
    ),
  );

  // Search for each keyword in both title and barcode
  final titleResults =
      palabrasClave.map((palabra) => fuseTitle.search(palabra)).toList();
  final barCodeResults =
      palabrasClave.map((palabra) => fuseBarCode.search(palabra)).toList();

  // Combine results, flatten, sort, and extract top products
  final allResults =
      [...titleResults, ...barCodeResults].expand((list) => list).toList();
  allResults.sort((a, b) => b.score.compareTo(a.score));
  final topProducts = allResults
      .take(20)
      .map((result) => productos.firstWhere(
          (p) => (p.title == result.item) || (p.barCode == result.item)))
      .toList();

  return topProducts.toSet().toList(); // Remove duplicates
}

List<Speech2OrderProduct> searchProducts4(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
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

  // Create Fuzzy instance with options
  final fuse = Fuzzy(
    productos.map((p) => p.title).toList(),
    options: FuzzyOptions(
      findAllMatches: true,
      tokenize: true,
      threshold: 0.5, // Adjust threshold as needed
    ),
  );

  // Search for each keyword
  final results = palabrasClave.map((palabra) => fuse.search(palabra)).toList();

  // Flatten results and sort by score (highest first)
  final allResults = results.expand((list) => list).toList();
  allResults.sort((a, b) => b.score.compareTo(a.score));

  // Extract top 20 products (considering duplicates)
  final topProducts = allResults
      .take(20)
      .map((result) => productos.firstWhere((p) => p.title == result.item))
      .toList();

  return topProducts.toSet().toList(); // Remove duplicates
}

List<Speech2OrderProduct> searchProducts2(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
  // Aplicar trim() a cada palabra clave para eliminar espacios al principio y al final
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

  // Verificar si alguna de las palabras clave coincide con el código de barras completo
  final productosCoincidentes = productos
      .where(
          (producto) => palabrasClave.contains(producto.barCode.toLowerCase()))
      .take(20)
      .toList();
  if (productosCoincidentes.isNotEmpty) return productosCoincidentes;

  // Si todas las palabras son números, buscar por los últimos 4 dígitos del código de barras
  if (palabrasClave.every((palabra) => RegExp(r'^\d+$').hasMatch(palabra))) {
    return productos
        .where((producto) => palabrasClave.any((ultimos4Digitos) =>
            producto.barCode.toLowerCase().endsWith(ultimos4Digitos)))
        .take(20)
        .toList();
  }

  // De lo contrario, buscar por palabras clave en el título
  return productos
      .where((producto) => palabrasClave.every((palabra) => producto.title
          .toLowerCase()
          .replaceAll(RegExp(r'[áàâãäå]'), 'a')
          .replaceAll(RegExp(r'[éèêë]'), 'e')
          .replaceAll(RegExp(r'[íìîï]'), 'i')
          .replaceAll(RegExp(r'[óòôõöø]'), 'o')
          .replaceAll(RegExp(r'[úùûü]'), 'u')
          .contains(palabra)))
      .take(20)
      .toList();
}

//? This method search with (tilde)
List<Speech2OrderProduct> searchProducts3(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
  // Aplicar trim() a cada palabra clave para eliminar espacios al principio y al final
  palabrasClave = palabrasClave.map((palabra) => palabra.trim()).toList();

  // Verificar si alguna de las palabras clave coincide con el código de barras completo
  final productosCoincidentes = productos
      .where((producto) => palabrasClave.contains(producto.barCode))
      .toList();
  if (productosCoincidentes.isNotEmpty) return productosCoincidentes;

  // Si todas las palabras son números, buscar por los últimos 4 dígitos del código de barras
  if (palabrasClave.every((palabra) => RegExp(r'^\d+$').hasMatch(palabra))) {
    return productos
        .where((producto) => palabrasClave.any(
            (ultimos4Digitos) => producto.barCode.endsWith(ultimos4Digitos)))
        .take(20)
        .toList();
  }

  // De lo contrario, buscar por palabras clave en el título
  return productos
      .where((producto) => palabrasClave.every((palabra) =>
          producto.title.toLowerCase().contains(palabra.toLowerCase())))
      .take(20)
      .toList();
}