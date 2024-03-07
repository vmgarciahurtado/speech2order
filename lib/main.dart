import 'package:flutter/material.dart';
import 'package:speech2order/model.dart';
import 'package:speech2order/process_record.dart';
import 'package:speech2order/select_products_dialog.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Speech2OrderPage extends StatefulWidget {
  const Speech2OrderPage({Key? key, required this.products}) : super(key: key);

  final List<Speech2OrderProduct> products;

  @override
  // ignore: library_private_types_in_public_api
  _Speech2OrderPageState createState() => _Speech2OrderPageState();
}

class _Speech2OrderPageState extends State<Speech2OrderPage> {
  final SpeechToText _speechToText = SpeechToText();
  static const _textStyle = TextStyle(fontSize: 20, color: Colors.black);
  final List<Map<String, dynamic>> _recognitionResult = [];

  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (_speechToText.isNotListening) {
      List<Map<String, dynamic>> response = await proccesRecordResult(
          speechText: result.recognizedWords, products: widget.products);
      if (response.isNotEmpty) {
        if (response.length <= 1) {
          setState(() {
            _recognitionResult.addAll(response);
          });
        } else {
          // ignore: use_build_context_synchronously
          List<Map<String, dynamic>> selectedItems = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return Speech2OrderSelectionDialog(items: response);
            },
          );

          if (selectedItems.isNotEmpty) {
            setState(() {
              _recognitionResult.addAll(selectedItems);
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  // If listening is active show the recognized words
                  _speechToText.isListening
                      ? _lastWords
                      // If listening isn't active but could be tell the user
                      // how to start it, otherwise indicate that speech
                      // recognition is not yet ready or not supported on
                      // the target device
                      : _speechEnabled
                          ? 'Tap the microphone to start listening...'
                          : 'Speech not available',
                ),
              ),
              Expanded(
                child: _recognitionResult.isNotEmpty
                    ? ListView.builder(
                        itemCount: _recognitionResult.length,
                        itemBuilder: (context, index) {
                          String title = _recognitionResult[index]['title'];
                          String code = _recognitionResult[index]['code'];
                          int quantity = _recognitionResult[index]['quantity'];

                          return Container(
                              color: Colors.lightBlue,
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Text(
                                      'title: $title\ncode: $code\nquantity: $quantity',
                                      style: _textStyle),
                                ],
                              ));
                        },
                      )
                    : const Text("No results yet"),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed:
                // If not yet listening for speech start, otherwise stop
                _speechToText.isNotListening ? _startListening : _stopListening,
            tooltip: 'Listen',
            child:
                Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
          ),
          const SizedBox(
            height: 10,
          ),
          Visibility(
            visible: _recognitionResult.isNotEmpty,
            child: FloatingActionButton(
              onPressed: () {
                _recognitionResult.clear();
                setState(() {});
              },
              tooltip: 'Clear',
              child: const Icon(Icons.clear),
            ),
          ),
          Visibility(
            visible: _recognitionResult.isNotEmpty,
            child: const SizedBox(
              height: 10,
            ),
          ),
          Visibility(
            visible: _recognitionResult.isNotEmpty,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pop(_recognitionResult);
              },
              tooltip: 'Complete',
              child: const Icon(Icons.card_travel_sharp),
            ),
          ),
        ],
      ),
    );
  }
}