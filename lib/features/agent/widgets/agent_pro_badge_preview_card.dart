import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Aperçu carte badge professionnel FONACO (layout aligné sur le PDF officiel).
class AgentProBadgePreviewCard extends StatelessWidget {
  final String agentName;
  final String specialty;
  final String agentCode;
  final String? phone;
  final String? zone;
  final String? photoUrl;
  final File? localPhoto;
  final bool isCertified;

  const AgentProBadgePreviewCard({
    super.key,
    required this.agentName,
    required this.specialty,
    required this.agentCode,
    this.phone,
    this.zone,
    this.photoUrl,
    this.localPhoto,
    this.isCertified = false,
  });

  static const _yellow = Color(0xFFFFD100);
  static const _orange = Color(0xFFC45A00);
  static const _dark = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final displayName = agentName.trim().isEmpty
        ? 'AGENT FONACO'
        : agentName.trim().toUpperCase();

    return AspectRatio(
      aspectRatio: 85.6 / 54,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _yellow, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              color: _yellow,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FONACO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: _dark,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'TA MISSION,',
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'NOTRE ACTION.',
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isCertified)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _yellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'AGENT CERTIFIÉ ★',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: _dark,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    if (isCertified) const SizedBox(height: 10),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _dark,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agent — $specialty',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8,
                        color: _orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PhotoAvatar(photoUrl: photoUrl, localPhoto: localPhoto),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _InfoLine('ID : $agentCode'),
                                if (phone != null && phone!.isNotEmpty)
                                  _InfoLine('Téléphone : $phone'),
                                if (zone != null && zone!.isNotEmpty)
                                  _InfoLine('Zone : $zone'),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: _yellow, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              size: 22,
                              color: _dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoAvatar extends StatelessWidget {
  final String? photoUrl;
  final File? localPhoto;

  const _PhotoAvatar({this.photoUrl, this.localPhoto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AgentProBadgePreviewCard._yellow,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: localPhoto != null
          ? Image.file(localPhoto!, fit: BoxFit.cover)
          : photoUrl != null && photoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.person, size: 22),
                )
              : ColoredBox(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 22, color: Colors.grey),
                ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;

  const _InfoLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 7,
          color: AgentProBadgePreviewCard._orange,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}
