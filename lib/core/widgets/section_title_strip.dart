import 'package:flutter/material.dart';

const _seeAllColor = Color(0xFFE0B800);

/// Rangée titre + lien « Voir plus / Voir tous » (design dashboard client).
class SectionTitleStrip extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final String? seeAllText;
  final VoidCallback? onSeeAllPressed;

  const SectionTitleStrip({
    super.key,
    required this.title,
    this.showSeeAll = true,
    this.seeAllText,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAllPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seeAllText ?? 'Voir plus',
                    style: const TextStyle(
                      color: _seeAllColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: _seeAllColor,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
