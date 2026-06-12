import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../widgets/fon_dialog.dart';

const _kTransactionPinKey = 'transaction_pin';

/// Retourne `true` si aucun PIN n'est configuré ou si le PIN saisi est correct.
/// Retourne `false` si l'utilisateur annule ou si le PIN est incorrect.
Future<bool> verifyTransactionPinIfRequired(BuildContext context) async {
  const storage = FlutterSecureStorage();
  final stored = await storage.read(key: _kTransactionPinKey);
  if (stored == null || stored.isEmpty) return true;

  if (!context.mounted) return false;

  final controller = TextEditingController();
  String? errorText;

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return FonDialog.alert(
            title: const Text('Code PIN de transaction'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Saisissez votre code PIN pour confirmer le paiement.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  style: const TextStyle(color: Colors.black),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Code PIN (4 chiffres)',
                    labelStyle: const TextStyle(color: Colors.black54),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (controller.text == stored) {
                      Navigator.pop(ctx, true);
                    } else {
                      setState(() => errorText = 'Code PIN incorrect');
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                style: FonDialog.secondaryActionStyle(),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: FonDialog.primaryActionStyle(),
                onPressed: () {
                  if (controller.text == stored) {
                    Navigator.pop(ctx, true);
                  } else {
                    setState(() => errorText = 'Code PIN incorrect');
                  }
                },
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return ok == true;
}
