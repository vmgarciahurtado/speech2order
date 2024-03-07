import 'package:speech2order/model.dart';
import 'package:speech2order/proccess_words.dart';
import 'package:speech2order/search.dart';

Future<List<Map<String, dynamic>>> proccesRecordResult(
    {required String speechText,
    required List<Speech2OrderProduct> products}) async {
  if (speechText.isEmpty) {
    return [];
  }

  List<Map<String, dynamic>> response = [];

  List<String> processedWords = processWords(speechText);
  int productQuantity = processProductQuantity(processedWords);
  if (productQuantity > 0) {
    processedWords = removeProductQuantity(processedWords);
  }

  List<Speech2OrderProduct> productsBySearch =
      searchProducts(products, processedWords);

  if (productsBySearch.isNotEmpty) {
    for (var product in productsBySearch) {
      Map<String, dynamic> item = {
        'title': product.title,
        'code': product.barCode,
        'quantity': productQuantity,
      };
      response.add(item);
    }

    return response;
  } else {
    return [];
  }
}
