import '../../domain/companion_state.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/challenge_localizations.dart';

class CompanionCopy {
  const CompanionCopy(this.title, this.message);
  final String title;
  final String message;
}

CompanionCopy companionCopy(
  AppLocalizations l10n,
  HydrionCompanionMood mood,
) {
  final source = switch (mood) {
    HydrionCompanionMood.goalComplete => (
        'Goal reached',
        'Goal reached. Great work listening to your routine.'
      ),
    HydrionCompanionMood.hotWeather => (
        'Weather-aware day',
        'Warm conditions changed today\'s goal. Keep it comfortable.'
      ),
    HydrionCompanionMood.challenge => (
        'Challenge current',
        'Nice. That moved today and your challenge forward.'
      ),
    HydrionCompanionMood.reminder => (
        'Gentle nudge',
        'A small check-in now keeps the day from bunching up later.'
      ),
    HydrionCompanionMood.recovery => (
        'Fresh start',
        'Good to see you. We can start fresh with one easy log.'
      ),
    HydrionCompanionMood.nearlyComplete => (
        'Almost there',
        'Nearly complete. Keep the finish gentle.'
      ),
    HydrionCompanionMood.onTrack || HydrionCompanionMood.streak => (
        'On track',
        'Halfway energy. Your routine has shape now.'
      ),
    HydrionCompanionMood.behindPace => (
        'Building momentum',
        'Nice start. A small top-up keeps the morning moving.'
      ),
    HydrionCompanionMood.morning => (
        'Morning check-in',
        'Let\'s make the first sip easy.'
      ),
  };
  return CompanionCopy(
    l10n.challengeText(source.$1),
    l10n.challengeText(source.$2),
  );
}
