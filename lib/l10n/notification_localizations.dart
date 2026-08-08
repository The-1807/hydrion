import '../services/policy_service.dart';
import 'app_localizations.dart';

extension HydrionNotificationLocalizations on AppLocalizations {
  String policyReminderMessage(Reminder reminder) {
    final french = localeName.toLowerCase().startsWith('fr');
    final spanish = localeName.toLowerCase().startsWith('es');
    return switch (reminder.messageCode) {
      ReminderPolicyMessageCode.urgentShortfall => french
          ? 'Il reste ${reminder.shortfallMl} ml. Prenez quelques gorgees maintenant.'
          : spanish
              ? 'Faltan ${reminder.shortfallMl} ml. Toma unos sorbos ahora.'
              : 'About ${reminder.shortfallMl} ml remains. Take a few sips now.',
      ReminderPolicyMessageCode.urgentCheck => french
          ? 'Verification rapide de l\'hydratation. Prenez quelques gorgees maintenant.'
          : spanish
              ? 'Revision rapida de hidratacion. Toma unos sorbos ahora.'
              : 'Quick hydration check. Take a few sips now.',
      ReminderPolicyMessageCode.mediumShortfall => french
          ? 'Il reste environ ${reminder.shortfallMl} ml. Une pause hydratation vous garde sur la bonne voie.'
          : spanish
              ? 'Faltan unos ${reminder.shortfallMl} ml. Una pausa de hidratacion te mantiene en camino.'
              : 'About ${reminder.shortfallMl} ml remains. A hydration break keeps you on pace.',
      ReminderPolicyMessageCode.mediumCheck => french
          ? 'Gardez un rythme regulier. Prenez bientot une pause hydratation.'
          : spanish
              ? 'Manten un ritmo constante. Haz pronto una pausa de hidratacion.'
              : 'Stay steady. Take a hydration break soon.',
      ReminderPolicyMessageCode.gentleNudge => french
          ? 'Petit rappel d\'hydratation. Quelques gorgees entretiennent l\'habitude.'
          : spanish
              ? 'Recordatorio suave de hidratacion. Unos sorbos mantienen el habito.'
              : 'Gentle hydration reminder. A few sips keep the habit moving.',
    };
  }
}
