import 'package:flutter/material.dart';

class SalesmanTopBar extends StatelessWidget {
  const SalesmanTopBar({super.key, this.onBackPress, required this.title});
  final Function()? onBackPress;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBackPress != null)
          IconButton(
            onPressed: onBackPress,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
