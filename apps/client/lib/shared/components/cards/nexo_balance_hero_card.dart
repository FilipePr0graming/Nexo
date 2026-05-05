import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import 'nexo_glass_card.dart';

class NexoBalanceHeroCard extends StatelessWidget {
  const NexoBalanceHeroCard({
    super.key,
    required this.title,
    required this.balance,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
  });

  final String title;
  final String balance;
  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NexoRadius.hero),
                boxShadow: [
                  BoxShadow(
                    color: NexoColors.accent.withValues(alpha: 0.18),
                    blurRadius: 52,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
            ),
          ),
        ),
        NexoGlassCard(
          radius: NexoRadius.hero,
          blurSigma: 22,
          tint: const Color(0xFF0E1018),
          borderColor: NexoColors.border.withValues(alpha: 0.65),
          padding: const EdgeInsets.all(NexoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: NexoColors.inkMedium,
                    ),
              ),
              const SizedBox(height: NexoSpacing.sm),
              ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF3D1B8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(rect);
                },
                child: Text(
                  balance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
              ),
              const SizedBox(height: NexoSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: primaryLabel,
                      value: primaryValue,
                    ),
                  ),
                  const SizedBox(width: NexoSpacing.md),
                  Expanded(
                    child: _HeroMetric(
                      label: secondaryLabel,
                      value: secondaryValue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexoSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(NexoRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: NexoSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
