import 'package:flutter/material.dart';

/// Modèle de données pour le résultat de l'analyse IA
/// Correspond à la structure JSON retournée par Mistral AI
class AiAnalysisResult {
  final String intent; // Catégorie de service (ex: "banque", "livraison")
  final String? location; // Ville ou quartier (ex: "Cocody", "Marcory")
  final String? time; // Moment (ex: "demain matin", "ce soir")
  final bool urgency; // Si urgent
  final String description; // Résumé du besoin
  final List<String> keywords; // Mots-clés pertinents

  const AiAnalysisResult({
    required this.intent,
    this.location,
    this.time,
    required this.urgency,
    required this.description,
    required this.keywords,
  });

  /// Crée un AiAnalysisResult à partir d'un JSON (réponse Mistral)
  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      intent: json['intent']?.toString() ?? 'service_général',
      location: json['location']?.toString(),
      time: json['time']?.toString(),
      urgency: json['urgency'] == true,
      description: json['description']?.toString() ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'location': location,
      'time': time,
      'urgency': urgency,
      'description': description,
      'keywords': keywords,
    };
  }

  /// Retourne les chips pour l'affichage UI
  List<AiChip> get chips {
    final chips = <AiChip>[];

    if (time != null && time!.isNotEmpty) {
      chips.add(AiChip(icon: Icons.schedule, label: time!));
    }

    if (location != null && location!.isNotEmpty) {
      chips.add(AiChip(icon: Icons.location_on, label: location!));
    }

    if (intent.isNotEmpty && intent != 'service_général') {
      chips.add(AiChip(icon: Icons.work, label: intent));
    }

    if (urgency) {
      chips.add(AiChip(icon: Icons.priority_high, label: 'Urgent'));
    }

    return chips;
  }

  @override
  String toString() {
    return 'AiAnalysisResult(intent: $intent, location: $location, time: $time, urgency: $urgency)';
  }
}

/// Modèle pour un chip d'affichage UI
class AiChip {
  final IconData icon;
  final String label;

  const AiChip({
    required this.icon,
    required this.label,
  });

  @override
  String toString() => 'AiChip($label)';
}
