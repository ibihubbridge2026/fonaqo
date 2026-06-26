import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Aperçu carte badge professionnel FONAQO — design officiel noir/or.
class AgentProBadgePreviewCard extends StatelessWidget {
  final String agentName;
  final String agentCode;
  final String? joinedDate;
  final String? photoUrl;
  final File? localPhoto;
  final bool isInternal;

  const AgentProBadgePreviewCard({
    super.key,
    required this.agentName,
    required this.agentCode,
    this.joinedDate,
    this.photoUrl,
    this.localPhoto,
    this.isInternal = false,
  });

  static const _gold = Color(0xFFFFC107);
  static const _dark = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final displayName = agentName.trim().isEmpty
        ? 'AGENT FONAQO'
        : agentName.trim().toUpperCase();

    return AspectRatio(
      aspectRatio: 54 / 86,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                _TopHeader(isInternal: isInternal),
                Expanded(
                  child: _BodyContent(
                    displayName: displayName,
                    agentCode: agentCode,
                    joinedDate: joinedDate ?? '—',
                  ),
                ),
                const _FooterBar(),
              ],
            ),
            Positioned(
              top: 82,
              left: 0,
              right: 0,
              child: Center(
                child: _PhotoWithSeal(
                  photoUrl: photoUrl,
                  localPhoto: localPhoto,
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 36,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _dark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final bool isInternal;

  const _TopHeader({required this.isInternal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(color: AgentProBadgePreviewCard._dark),
          Positioned(
            right: 8,
            top: 12,
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                size: const Size(48, 48),
                painter: _ShieldPainter(color: AgentProBadgePreviewCard._gold, letter: 'F', fontSize: 28),
              ),
            ),
          ),
          Positioned(
            left: -4,
            right: -4,
            bottom: -6,
            child: CustomPaint(
              size: const Size(double.infinity, 14),
              painter: _WavePainter(),
            ),
          ),
          if (isInternal)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 44,
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                decoration: const BoxDecoration(
                  color: AgentProBadgePreviewCard._gold,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 14, color: AgentProBadgePreviewCard._dark),
                    const SizedBox(height: 2),
                    const Text(
                      'AGENT\nINTERNE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 5.5,
                        fontWeight: FontWeight.w900,
                        color: AgentProBadgePreviewCard._dark,
                        height: 1.1,
                      ),
                    ),
                    const Text('★ ★ ★', style: TextStyle(fontSize: 6, color: AgentProBadgePreviewCard._dark)),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: 22,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(22, 26),
                      painter: _ShieldPainter(
                        color: AgentProBadgePreviewCard._gold,
                        letter: 'F',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'FONAQO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'TA MISSION, NOTRE ACTION.',
                  style: TextStyle(
                    fontSize: 6.5,
                    fontWeight: FontWeight.w700,
                    color: AgentProBadgePreviewCard._gold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends StatelessWidget {
  final String displayName;
  final String agentCode;
  final String joinedDate;

  const _BodyContent({
    required this.displayName,
    required this.agentCode,
    required this.joinedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 52, 12, 8),
      child: Column(
        children: [
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AgentProBadgePreviewCard._dark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AgentProBadgePreviewCard._dark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '—  AGENT DE TERRAIN  —',
              style: TextStyle(
                fontSize: 6.5,
                fontWeight: FontWeight.w800,
                color: AgentProBadgePreviewCard._gold,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.badge_outlined, label: 'ID AGENT', value: agentCode),
          const Divider(height: 1, color: Color(0xFFDDDDDD)),
          _InfoRow(icon: Icons.calendar_today_outlined, label: 'INSCRIT DEPUIS', value: joinedDate),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomPaint(
                      size: const Size(70, 18),
                      painter: _SignaturePainter(),
                    ),
                    Container(
                      width: 70,
                      height: 1.5,
                      color: AgentProBadgePreviewCard._gold,
                      margin: const EdgeInsets.only(top: 2, bottom: 2),
                    ),
                    Text(
                      'SIGNATURE AUTORISÉE',
                      style: TextStyle(
                        fontSize: 5.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    color: Colors.white,
                    child: const Icon(Icons.qr_code_2, size: 38, color: AgentProBadgePreviewCard._dark),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'VÉRIFIER CE BADGE',
                    style: TextStyle(
                      fontSize: 5.5,
                      fontWeight: FontWeight.w700,
                      color: AgentProBadgePreviewCard._dark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoWithSeal extends StatelessWidget {
  final String? photoUrl;
  final File? localPhoto;

  const _PhotoWithSeal({this.photoUrl, this.localPhoto});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AgentProBadgePreviewCard._gold, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPhoto(),
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: CustomPaint(size: const Size(28, 28), painter: _SealPainter()),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (localPhoto != null) {
      return Image.file(localPhoto!, fit: BoxFit.cover);
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const Icon(Icons.person, size: 36),
      );
    }
    return ColoredBox(
      color: const Color(0xFFEAEAEA),
      child: const Icon(Icons.person, size: 36, color: Colors.grey),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AgentProBadgePreviewCard._dark,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 11, color: AgentProBadgePreviewCard._gold),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: AgentProBadgePreviewCard._dark,
              ),
            ),
          ),
          Container(width: 1, height: 14, color: const Color(0xFFDDDDDD), margin: const EdgeInsets.symmetric(horizontal: 4)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: AgentProBadgePreviewCard._dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: AgentProBadgePreviewCard._dark,
      child: Row(
        children: [
          CustomPaint(
            size: const Size(12, 14),
            painter: _ShieldPainter(color: AgentProBadgePreviewCard._gold, letter: '✓', fontSize: 7),
          ),
          const SizedBox(width: 4),
          const Text(
            'VOTRE CONFIANCE, ',
            style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Text(
            'NOTRE ENGAGEMENT.',
            style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: AgentProBadgePreviewCard._gold),
          ),
        ],
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color color;
  final String letter;
  final double fontSize;

  _ShieldPainter({required this.color, required this.letter, required this.fontSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.15)
      ..lineTo(size.width, size.height * 0.15)
      ..lineTo(size.width, size.height * 0.55)
      ..quadraticBezierTo(size.width, size.height * 0.05, size.width / 2, size.height)
      ..quadraticBezierTo(0, size.height * 0.05, 0, size.height * 0.55)
      ..close();
    canvas.drawPath(path, paint);
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(color: AgentProBadgePreviewCard._dark, fontSize: fontSize, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.28));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AgentProBadgePreviewCard._gold;
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.3, size.height * 1.2, size.width * 0.55, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.75, -size.height * 0.3, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height * 0.6)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final teeth = 16;
    final outer = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final angle = (math.pi * i / teeth) - math.pi / 2;
      final radius = i.isEven ? r : r * 0.78;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        outer.moveTo(x, y);
      } else {
        outer.lineTo(x, y);
      }
    }
    outer.close();
    canvas.drawPath(outer, Paint()..color = AgentProBadgePreviewCard._gold);
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = AgentProBadgePreviewCard._dark);
    final check = Paint()
      ..color = AgentProBadgePreviewCard._gold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 5, cy), Offset(cx - 1, cy + 4), check);
    canvas.drawLine(Offset(cx - 1, cy + 4), Offset(cx + 6, cy - 5), check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AgentProBadgePreviewCard._dark
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.1, size.width * 0.35, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.95, size.width * 0.65, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.05, size.width, size.height * 0.5);
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width * 0.85, size.height - 2),
      Paint()..color = const Color(0xFFCCCCCC)..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
