import 'package:flutter/material.dart';

/// Composants Skeleton Loading pour améliorer l'UX pendant le chargement
/// Remplace les CircularProgressIndicator par des placeholders visuels
class SkeletonLoading {
  /// Skeleton pour une carte de mission
  static Widget missionCard({double? height}) {
    return _MissionCardSkeleton(height: height);
  }

  /// Skeleton pour une carte d'agent
  static Widget agentCard({double? height}) {
    return _AgentCardSkeleton(height: height);
  }

  /// Skeleton pour une carte dashboard
  static Widget dashboardCard({double? height}) {
    return _DashboardCardSkeleton(height: height);
  }

  /// Skeleton pour une liste verticale
  static Widget list({int itemCount = 3, Widget Function(int)? itemBuilder}) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return itemBuilder?.call(index) ?? _DefaultListItemSkeleton();
      },
    );
  }

  /// Skeleton pour la liste des conversations (onglet Messages).
  static Widget conversationList({int itemCount = 6}) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _ConversationRowSkeleton(),
    );
  }
}

/// Skeleton pour une carte de mission
class _MissionCardSkeleton extends StatelessWidget {
  final double? height;

  const _MissionCardSkeleton({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la mission
          _SkeletonBlock(
            width: double.infinity,
            height: 20,
            marginBottom: 12,
          ),
          // Description
          _SkeletonBlock(
            width: double.infinity,
            height: 14,
            marginBottom: 8,
          ),
          _SkeletonBlock(
            width: 0.7,
            height: 14,
            marginBottom: 12,
          ),
          // Badge statut + prix
          Row(
            children: [
              _SkeletonBlock(
                width: 80,
                height: 24,
                borderRadius: 12,
              ),
              const Spacer(),
              _SkeletonBlock(
                width: 100,
                height: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton pour une carte d'agent
class _AgentCardSkeleton extends StatelessWidget {
  final double? height;

  const _AgentCardSkeleton({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          _SkeletonCircle(
            diameter: 60,
          ),
          const SizedBox(width: 12),
          // Info agent
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SkeletonBlock(
                  width: 0.6,
                  height: 18,
                  marginBottom: 8,
                ),
                _SkeletonBlock(
                  width: 0.4,
                  height: 14,
                  marginBottom: 8,
                ),
                Row(
                  children: [
                    _SkeletonBlock(
                      width: 60,
                      height: 16,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 8),
                    _SkeletonBlock(
                      width: 40,
                      height: 16,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton pour une carte dashboard
class _DashboardCardSkeleton extends StatelessWidget {
  final double? height;

  const _DashboardCardSkeleton({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _SkeletonBlock(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBlock(
                      width: 0.5,
                      height: 16,
                      marginBottom: 4,
                    ),
                    _SkeletonBlock(
                      width: 0.3,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          _SkeletonBlock(
            width: double.infinity,
            height: 24,
            marginBottom: 8,
          ),
          _SkeletonBlock(
            width: 0.8,
            height: 16,
          ),
        ],
      ),
    );
  }
}

/// Skeleton d'une ligne de conversation (avatar + nom + aperçu).
class _ConversationRowSkeleton extends StatelessWidget {
  const _ConversationRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          _SkeletonCircle(diameter: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SkeletonBlock(
                        width: 0.55,
                        height: 14,
                        borderRadius: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SkeletonBlock(
                      width: 36,
                      height: 10,
                      borderRadius: 6,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SkeletonBlock(
                  width: 0.75,
                  height: 12,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton pour un item de liste par défaut
class _DefaultListItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _SkeletonCircle(diameter: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SkeletonBlock(
                  width: 0.6,
                  height: 16,
                  marginBottom: 8,
                ),
                _SkeletonBlock(
                  width: 0.4,
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloc skeleton animé
class _SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double? marginBottom;
  final double borderRadius;

  const _SkeletonBlock({
    this.width,
    required this.height,
    this.marginBottom,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: width != null ? (width! > 1 ? width : screenWidth * width!) : null,
      height: height,
      margin:
          marginBottom != null ? EdgeInsets.only(bottom: marginBottom!) : null,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _ShimmerEffect(),
    );
  }
}

/// Cercle skeleton animé
class _SkeletonCircle extends StatelessWidget {
  final double diameter;

  const _SkeletonCircle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: _ShimmerEffect(),
    );
  }
}

/// Effet shimmer animé
class _ShimmerEffect extends StatefulWidget {
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(color: Colors.grey[300]),
    );
  }
}

/// Transform pour le gradient animé
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
