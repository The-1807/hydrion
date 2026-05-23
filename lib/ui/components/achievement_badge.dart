import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  final String badgeName;
  final bool isUnlocked;

  const AchievementBadge({
    super.key,
    required this.badgeName,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label:
          'Achievement badge: $badgeName ${isUnlocked ? 'unlocked' : 'locked'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked ? scheme.primary : scheme.surfaceContainerHighest,
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: scheme.primary.withAlpha(89),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
          border: Border.all(
            color: isUnlocked ? scheme.primary : scheme.outlineVariant,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isUnlocked ? 1.06 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock,
                color: isUnlocked ? scheme.onPrimary : scheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 84,
                child: Text(
                  badgeName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isUnlocked
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
