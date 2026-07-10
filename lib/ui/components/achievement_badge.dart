import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final status = isUnlocked
        ? l10n.achievementStatusUnlocked
        : l10n.achievementStatusLocked;

    return Semantics(
      label: l10n.achievementBadgeSemantics(
        badgeName: badgeName,
        status: status,
      ),
      child: SizedBox.square(
        dimension: 112,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(10),
          alignment: Alignment.center,
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
            scale: isUnlocked ? 1.04 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUnlocked ? Icons.emoji_events : Icons.lock,
                  color:
                      isUnlocked ? scheme.onPrimary : scheme.onSurfaceVariant,
                  size: 26,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 78,
                  child: Text(
                    badgeName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isUnlocked
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
