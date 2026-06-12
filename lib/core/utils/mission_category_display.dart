import 'package:flutter/material.dart';

/// Filtre les catégories API pour n'afficher que les 3 reines + « Autre service ».
List<Map<String, dynamic>> buildMissionCategoryGrid(
  List<Map<String, dynamic>> apiCategories,
) {
  const slots = [
    ('livraison', Icons.local_shipping_outlined),
    ('courses', Icons.shopping_bag_outlined),
    ('transport', Icons.directions_car_outlined),
  ];

  final result = <Map<String, dynamic>>[];
  var syntheticCounter = -10;

  for (final slot in slots) {
    final keyword = slot.$1;
    final icon = slot.$2;
    Map<String, dynamic>? match;
    for (final c in apiCategories) {
      final name = c['name']?.toString().toLowerCase() ?? '';
      if (name.contains(keyword)) {
        match = Map<String, dynamic>.from(c);
        break;
      }
    }
    final rawId = match?['id'];
    final resolvedId = rawId is int
        ? rawId
        : int.tryParse('$rawId') ?? syntheticCounter--;
    result.add({
      'id': resolvedId,
      'name': match?['name']?.toString() ??
          keyword[0].toUpperCase() + keyword.substring(1),
      'icon': icon,
      'synthetic': match == null,
    });
  }

  result.add({
    'id': -1,
    'name': 'Autre service',
    'icon': Icons.more_horiz_rounded,
    'synthetic': true,
  });

  return result;
}

int? resolveCategoryIdForPayload(int? selectedId) {
  if (selectedId == null || selectedId < 0) return null;
  return selectedId;
}
