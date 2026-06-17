import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fonaco/l10n/app_localizations.dart';
import 'package:fonaco/features/client/leboncoin/models/local_listing_model.dart';
import 'package:fonaco/features/client/leboncoin/repositories/leboncoin_repository.dart';

/// LeBonCoin — annuaire local : artisans experts et bons plans (carte + fiches).
class LeBonCoinScreen extends StatefulWidget {
  const LeBonCoinScreen({super.key});

  @override
  State<LeBonCoinScreen> createState() => _LeBonCoinScreenState();
}

class _LeBonCoinScreenState extends State<LeBonCoinScreen> {
  static const _black = Color(0xFF000000);
  static const _accent = Color(0xFFFFD400);

  final _repo = LeBonCoinRepository();
  final _searchController = TextEditingController();

  List<LocalListingModel> _listings = [];
  LeBonCoinFilter _filter = LeBonCoinFilter.all;
  bool _loading = true;
  bool _mapView = true;
  LocalListingModel? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    double? lat;
    double? lng;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      lat = leBonCoinDefaultLat;
      lng = leBonCoinDefaultLng;
    }

    final items = await _repo.fetchListingsWithPlaces(
      filter: _filter,
      query: _searchController.text,
      latitude: lat,
      longitude: lng,
    );
    if (!mounted) return;
    setState(() {
      _listings = items;
      _loading = false;
      if (_selected != null &&
          !items.any((e) => e.id == _selected!.id)) {
        _selected = null;
      }
    });
  }

  Set<Marker> get _markers {
    return _listings
        .where((e) => e.hasCoordinates)
        .map(
          (e) => Marker(
            markerId: MarkerId(e.id),
            position: LatLng(e.latitude!, e.longitude!),
            infoWindow: InfoWindow(title: e.name, snippet: e.displayCategory),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _markerHueForCategory(e.category),
            ),
            onTap: () => setState(() => _selected = e),
          ),
        )
        .toSet();
  }

  double _markerHueForCategory(String category) {
    switch (category) {
      case 'artisan':
        return BitmapDescriptor.hueYellow;
      case 'restaurant':
        return BitmapDescriptor.hueOrange;
      case 'shop':
        return BitmapDescriptor.hueAzure;
      case 'leisure':
        return BitmapDescriptor.hueGreen;
      case 'gym':
        return BitmapDescriptor.hueRose;
      case 'museum':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Future<void> _openWebsite(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD400), Color(0xFFFFF3B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.leBonCoinTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.leBonCoinSubtitle,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: l10n.leBonCoinSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: LeBonCoinFilter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label(l10n)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _filter = f);
                        _load();
                      },
                      selectedColor: _accent,
                      checkmarkColor: _black,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? _black : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _ViewToggle(
                    label: l10n.leBonCoinMap,
                    icon: Icons.map_outlined,
                    selected: _mapView,
                    onTap: () => setState(() => _mapView = true),
                  ),
                  const SizedBox(width: 8),
                  _ViewToggle(
                    label: l10n.leBonCoinList,
                    icon: Icons.view_list_outlined,
                    selected: !_mapView,
                    onTap: () => setState(() => _mapView = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _listings.isEmpty
                      ? Center(
                          child: Text(
                            l10n.leBonCoinEmpty,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : _mapView ? _buildMap() : _buildList(),
            ),
            if (_selected != null)
              _DetailSheet(
                listing: _selected!,
                websiteLabel: l10n.leBonCoinWebsite,
                onClose: () => setState(() => _selected = null),
                onWebsite: () => _openWebsite(_selected!.websiteUrl),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(leBonCoinDefaultLat, leBonCoinDefaultLng),
            zoom: 13,
          ),
          markers: _markers,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          onTap: (_) => setState(() => _selected = null),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _listings.length,
      itemBuilder: (context, index) {
        final item = _listings[index];
        return _ListingCard(
          listing: item,
          onTap: () => setState(() => _selected = item),
        );
      },
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD400) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final LocalListingModel listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFD400).withValues(alpha: 0.2),
                child: Icon(
                  _iconForCategory(listing.category),
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.specialty.isNotEmpty
                          ? listing.specialty
                          : listing.displayCategory,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    Text(
                      listing.locationLabel,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (listing.isFeatured)
                const Icon(Icons.star, color: Color(0xFFFFD400), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final LocalListingModel listing;
  final String websiteLabel;
  final VoidCallback onClose;
  final VoidCallback onWebsite;

  const _DetailSheet({
    required this.listing,
    required this.websiteLabel,
    required this.onClose,
    required this.onWebsite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  listing.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          Text(
            listing.displayCategory,
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          if (listing.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(listing.description, style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16),
              const SizedBox(width: 4),
              Expanded(child: Text(listing.locationLabel)),
            ],
          ),
          if (listing.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16),
                const SizedBox(width: 4),
                Text(listing.phone),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (listing.websiteUrl != null && listing.websiteUrl!.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onWebsite,
                    icon: const Icon(Icons.language),
                    label: Text(websiteLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'artisan':
      return Icons.construction_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'shop':
      return Icons.storefront_outlined;
    case 'leisure':
      return Icons.beach_access_outlined;
    default:
      return Icons.place_outlined;
  }
}
