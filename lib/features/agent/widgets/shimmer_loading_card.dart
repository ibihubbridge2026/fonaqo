import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget pour afficher un effet shimmer pendant le chargement
class ShimmerLoadingCard extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoadingCard({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey.shade300,
      highlightColor: highlightColor ?? Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Widget pour le chargement du solde wallet
class WalletShimmer extends StatelessWidget {
  const WalletShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerLoadingCard(
          width: 120,
          height: 14,
        ),
        const SizedBox(height: 12),
        const ShimmerLoadingCard(
          width: 180,
          height: 32,
        ),
        const SizedBox(height: 8),
        ShimmerLoadingCard(
          width: 100,
          height: 13,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// Widget pour le chargement des statistiques
class StatsShimmer extends StatelessWidget {
  const StatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    ShimmerLoadingCard(
                      width: 40,
                      height: 24,
                    ),
                    SizedBox(height: 8),
                    ShimmerLoadingCard(
                      width: 60,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    ShimmerLoadingCard(
                      width: 60,
                      height: 24,
                    ),
                    SizedBox(height: 8),
                    ShimmerLoadingCard(
                      width: 50,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    ShimmerLoadingCard(
                      width: 40,
                      height: 24,
                    ),
                    SizedBox(height: 8),
                    ShimmerLoadingCard(
                      width: 40,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    ShimmerLoadingCard(
                      width: 40,
                      height: 24,
                    ),
                    SizedBox(height: 8),
                    ShimmerLoadingCard(
                      width: 50,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget pour le chargement des cartes de mission
class MissionCardShimmer extends StatelessWidget {
  const MissionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ShimmerLoadingCard(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoadingCard(
                      width: 150,
                      height: 15,
                    ),
                    const SizedBox(height: 4),
                    const ShimmerLoadingCard(
                      width: 100,
                      height: 13,
                    ),
                    const SizedBox(height: 8),
                    const ShimmerLoadingCard(
                      width: 80,
                      height: 12,
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerLoadingCard(
                    width: 60,
                    height: 16,
                  ),
                  SizedBox(height: 6),
                  ShimmerLoadingCard(
                    width: 70,
                    height: 20,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const ShimmerLoadingCard(
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 6),
              const ShimmerLoadingCard(
                width: 60,
                height: 14,
              ),
              const Spacer(),
              ShimmerLoadingCard(
                width: 80,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
