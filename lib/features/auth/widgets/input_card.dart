import 'package:flutter/material.dart';

class InputCard extends StatelessWidget {
  final Widget child;
  const InputCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}
