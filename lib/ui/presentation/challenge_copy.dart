import 'package:flutter/widgets.dart';

import '../../domain/hydration_contracts.dart';

class ChallengeCopy {
  final String title;
  final String description;

  const ChallengeCopy(this.title, this.description);

  static ChallengeCopy forChallenge(
    BuildContext context,
    HydrationChallenge challenge,
  ) {
    final language = Localizations.localeOf(context).languageCode;
    return (_copy[language] ?? _copy['en']!)[challenge.id] ??
        ChallengeCopy(challenge.name, challenge.description);
  }

  static const _copy = <String, Map<String, ChallengeCopy>>{
    'en': {
      'lunch-break-refill': ChallengeCopy('Lunch Break Refill', 'Use a lunch break to check and refill your bottle when useful.'),
      'homework-hydration': ChallengeCopy('Homework Hydration', 'Pair a comfortable hydration check with a study break.'),
      'after-school-recharge': ChallengeCopy('After-School Recharge', 'Pause after your daytime routine and review your hydration.'),
      'backpack-bottle-check': ChallengeCopy('Backpack Bottle Check', 'Use a packing cue to prepare a reusable bottle.'),
      'desk-day-reset': ChallengeCopy('Desk-Day Reset', 'Use an optional seated break to review your hydration.'),
      'shift-hydration-check': ChallengeCopy('Shift Hydration Check', 'Add an optional hydration check midway through a work period.'),
      'commute-cup': ChallengeCopy('Commute Cup', 'Use departure or arrival as an optional hydration cue.'),
      'evening-goal-review': ChallengeCopy('Evening Goal Review', 'Review your day and decide whether your plan still feels right.'),
    },
    'fr': {
      'lunch-break-refill': ChallengeCopy('Remplissage du midi', 'Profitez du repas pour vérifier et remplir votre gourde au besoin.'),
      'homework-hydration': ChallengeCopy('Hydratation et étude', 'Associez une vérification confortable à une pause d’étude.'),
      'after-school-recharge': ChallengeCopy('Recharge de l’après-midi', 'Faites une pause après votre routine et vérifiez votre hydratation.'),
      'backpack-bottle-check': ChallengeCopy('Vérification de la gourde', 'Utilisez la préparation du sac pour penser à votre gourde.'),
      'desk-day-reset': ChallengeCopy('Pause assise', 'Profitez d’une pause assise facultative pour revoir votre hydratation.'),
      'shift-hydration-check': ChallengeCopy('Vérification à mi-parcours', 'Ajoutez une vérification facultative au milieu d’une période de travail.'),
      'commute-cup': ChallengeCopy('Gourde en déplacement', 'Utilisez le départ ou l’arrivée comme rappel facultatif.'),
      'evening-goal-review': ChallengeCopy('Bilan du soir', 'Revoyez votre journée et vérifiez si votre plan vous convient.'),
    },
    'es': {
      'lunch-break-refill': ChallengeCopy('Recarga del almuerzo', 'Aprovecha el almuerzo para revisar y llenar tu botella si hace falta.'),
      'homework-hydration': ChallengeCopy('Hidratación y estudio', 'Asocia una revisión cómoda con una pausa de estudio.'),
      'after-school-recharge': ChallengeCopy('Recarga de la tarde', 'Haz una pausa tras tu rutina y revisa tu hidratación.'),
      'backpack-bottle-check': ChallengeCopy('Revisión de la botella', 'Usa la preparación de la mochila para dejar lista tu botella.'),
      'desk-day-reset': ChallengeCopy('Pausa sentado', 'Usa una pausa opcional para revisar tu hidratación.'),
      'shift-hydration-check': ChallengeCopy('Revisión a mitad de jornada', 'Añade una revisión opcional a mitad de un periodo de trabajo.'),
      'commute-cup': ChallengeCopy('Vaso de viaje', 'Usa la salida o la llegada como recordatorio opcional.'),
      'evening-goal-review': ChallengeCopy('Revisión de la tarde', 'Revisa tu día y decide si tu plan todavía te resulta adecuado.'),
    },
  };
}
