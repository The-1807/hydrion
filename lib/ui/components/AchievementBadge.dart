import 'package:flutter/material.dart';

/// AchievementBadge — celebratory badge with subtle animation.
/// - Circle badge color reflects unlock state
/// - Scales on unlock for a tiny dopamine spark
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
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Achievement badge: $badgeName ${isUnlocked ? 'unlocked' : 'locked'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked ? cs.primary : cs.surfaceVariant,
          boxShadow: isUnlocked
              ? [BoxShadow(color: cs.primary.withOpacity(0.35), blurRadius: 12, spreadRadius: 1)]
              : const [],
          border: Border.all(
            color: isUnlocked ? cs.primary : cs.outlineVariant,
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
                color: isUnlocked ? cs.onPrimary : cs.onSurfaceVariant,
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
                        color: isUnlocked ? cs.onPrimary : cs.onSurfaceVariant,
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
