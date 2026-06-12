import 'dart:async';

import 'package:flutter/material.dart';

import '../services/address_search_service.dart';

typedef OnAddressLocationSelected = void Function(
  String address,
  double latitude,
  double longitude,
);

/// Champ adresse avec suggestions géocodées et bouton « position actuelle ».
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final OnAddressLocationSelected? onLocationSelected;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.label = 'Adresse (obligatoire)',
    this.onLocationSelected,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final AddressSearchService _search = AddressSearchService();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = [];
  bool _loadingGps = false;
  bool _loadingSearch = false;

  static const _fieldDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFE8E8E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFE8E8E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFFFD400), width: 1.5),
    ),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      final q = widget.controller.text.trim();
      if (q.length < 2) {
        setState(() {
          _suggestions = [];
          _loadingSearch = false;
        });
        _removeOverlay();
        return;
      }
      setState(() => _loadingSearch = true);
      final results = await _search.search(q);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loadingSearch = false;
      });
      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _selectSuggestion(AddressSuggestion s) {
    widget.controller.text = s.label;
    widget.onLocationSelected?.call(s.label, s.latitude, s.longitude);
    setState(() => _suggestions = []);
    _removeOverlay();
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingGps = true);
    final result = await _search.useCurrentLocation();
    if (!mounted) return;
    setState(() => _loadingGps = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d\'obtenir votre position. Activez le GPS.',
          ),
        ),
      );
      return;
    }
    _selectSuggestion(result);
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 72,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    s.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: s.subtitle == null
                      ? null
                      : Text(
                          s.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFB8860B)),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: widget.controller,
            maxLines: 2,
            decoration: _fieldDecoration.copyWith(
              hintText: 'Ex. Camp Guezo, Cotonou…',
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
              suffixIcon: _loadingSearch
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onTapOutside: (_) => _removeOverlay(),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _loadingGps ? null : _useCurrentLocation,
          icon: _loadingGps
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 18),
          label: const Text('Utiliser ma position actuelle'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }
}
