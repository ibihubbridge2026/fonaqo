import 'package:flutter/material.dart';
import 'input_card.dart';
import '../../../core/models/country_model.dart';

class PhoneInputCard extends StatelessWidget {
  final Country country;
  final VoidCallback onCountryPressed;
  final TextEditingController controller;

  const PhoneInputCard({
    super.key,
    required this.country,
    required this.onCountryPressed,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return InputCard(
      child: Row(
        children: [
          InkWell(
            onTap: onCountryPressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                '${country.flag} ${country.dialCode}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: false,
              focusNode: FocusNode(),
              decoration: const InputDecoration(
                hintText: 'Numéro de téléphone',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Country?> pickCountry(BuildContext context, Country current) {
  const countries = Country.availableCountries;

  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choisir un pays',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                ...countries.map((c) {
                  final selected = c.dialCode == current.dialCode;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      c.dialCode,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () => Navigator.pop(context, c),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}
