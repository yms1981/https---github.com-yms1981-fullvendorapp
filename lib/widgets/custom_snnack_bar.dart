import 'package:flutter/material.dart';

class MySnackBarContent extends StatefulWidget {
  final String initialText;
  final Function(String) onTextUpdated;

  const MySnackBarContent({
    super.key,
    required this.initialText,
    required this.onTextUpdated,
  });

  @override
  State<MySnackBarContent> createState() => _MySnackBarContentState();
}

class _MySnackBarContentState extends State<MySnackBarContent> {
  String _text = '';

  @override
  void initState() {
    super.initState();
    _text = widget.initialText;
  }

  void updateText(String newText) {
    setState(() {
      _text = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: const TextStyle(color: Colors.white),
    );
  }
}
