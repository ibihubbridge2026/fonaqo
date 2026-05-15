import 'package:flutter/material.dart';
import 'package:fonaco/core/models/country_model.dart';

/// Sélecteur de pays avec drapeau et indicatif téléphonique
class CountrySelector extends StatefulWidget {
  final Country? selectedCountry;
  final Function(Country) onCountrySelected;

  const CountrySelector({
    super.key,
    this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.selectedCountry ?? Country.defaultCountry;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity( 0.3)),
        ),
        child: Row(
          children: [
            Text(
              _selectedCountry.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCountry.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _selectedCountry.dialCode,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Sélectionner un pays',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: Country.availableCountries.length,
                itemBuilder: (context, index) {
                  final country = Country.availableCountries[index];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      country.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      country.dialCode,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      widget.onCountrySelected(country);
                      Navigator.of(context).pop();
                    },
                    selected: _selectedCountry.code == country.code,
                    selectedTileColor: Colors.orange.withOpacity( 0.1),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
