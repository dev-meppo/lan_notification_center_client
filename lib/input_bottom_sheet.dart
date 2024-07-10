import 'package:flutter/material.dart';
import 'dart:io';

/// Modify this function to customize your bottom sheet input.
Future<String?> showInputBottomSheet(
  BuildContext context, {
  required String label,
  required String initialText,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: TextInput(
          label: Text(
            label,
            style: TextStyle(fontSize: 13),
          ),
          textAlign: TextAlign.center,
          initialText: initialText,
        ),
      );
    },
  );
}

class TextInput extends StatefulWidget {
  const TextInput({
    super.key,
    this.label,
    required this.textAlign,
    required this.initialText,
  });

  final Widget? label;
  final TextAlign textAlign;
  final String initialText;

  @override
  _TextInputState createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller.text = widget.initialText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget? getLabel() {
    if (widget.label != null) {
      if (widget.textAlign == TextAlign.center) {
        return Center(child: widget.label);
      } else {
        return widget.label!;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            borderRadius: BorderRadius.circular(25),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextField(
                textAlign: widget.textAlign,
                controller: _controller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: getLabel(),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Material(
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  Navigator.pop(context, _controller.text);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 8),
                  child: Text("Save"),
                )),
          ),
        ],
      ),
    );
  }
}
