import 'package:flutter/material.dart';

/// Modals FONACO — fond blanc pur, typographie sombre.
class FonDialog {
  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  static AlertDialog alert({
    required Widget title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: _shape,
      title: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        child: title,
      ),
      content: DefaultTextStyle(
        style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
        child: content,
      ),
      actions: actions,
    );
  }

  static ButtonStyle primaryActionStyle() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD400),
        foregroundColor: Colors.black,
        elevation: 0,
      );

  static ButtonStyle secondaryActionStyle() => TextButton.styleFrom(
        foregroundColor: Colors.black87,
      );
}
