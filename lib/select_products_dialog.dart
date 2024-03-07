import 'package:flutter/material.dart';

class Speech2OrderSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const Speech2OrderSelectionDialog({Key? key, required this.items})
      : super(key: key);

  @override
  Speech2OrderSelectionDialogState createState() =>
      Speech2OrderSelectionDialogState();
}

class Speech2OrderSelectionDialogState
    extends State<Speech2OrderSelectionDialog> {
  late List<bool> _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = List.filled(widget.items.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select items to add"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.items.length,
            (index) {
              String title = widget.items[index]['title'];
              String code = widget.items[index]['code'];
              int quantity = widget.items[index]['quantity'];

              return CheckboxListTile(
                title: Text('title: $title\ncode: $code\nquantity: $quantity'),
                value: _isSelected[index],
                onChanged: (bool? value) {
                  setState(() {
                    _isSelected[index] = value!;
                  });
                },
              );
            },
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            List<Map<String, dynamic>> selectedItems = [];
            for (int i = 0; i < widget.items.length; i++) {
              if (_isSelected[i]) {
                selectedItems.add(widget.items[i]);
              }
            }
            Navigator.of(context).pop(selectedItems);
          },
          child: const Text("Accept"),
        ),
      ],
    );
  }
}
