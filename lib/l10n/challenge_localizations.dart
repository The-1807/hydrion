import 'app_localizations.dart';

class LocalizedChallengeCopy {
  final String title;
  final String description;

  const LocalizedChallengeCopy({
    required this.title,
    required this.description,
  });
}

const _legacyChallengeFrenchText = <String, String>{
  'Try seven no-added-sugar infusion themes while maintaining your normal hydration goal.':
      'Essayez sept themes d\'infusion sans sucre ajoute tout en maintenant votre objectif d\'hydratation habituel.',
  'Review today’s infusion theme.': 'Consultez le theme d\'infusion du jour.',
  'Confirm no added sugar.': 'Confirmez l\'absence de sucre ajoute.',
  'Log the amount of infused water actually consumed.':
      'Enregistrez la quantite d\'eau infusee reellement consommee.',
  'A canonical hydration log created for today’s assigned infusion theme.':
      'Un journal d\'hydratation canonique cree pour le theme d\'infusion attribue aujourd\'hui.',
  'Plain water supports the daily goal but does not complete the infusion task.':
      'L\'eau nature contribue a l\'objectif quotidien, mais ne termine pas la tache d\'infusion.',
  'Citrus': 'Agrumes',
  'Berry': 'Baies',
  'Tropical fruit': 'Fruit tropical',
  'Herb': 'Herbes',
  'Fruit and herb': 'Fruit et herbes',
  'Cucumber or fresh produce': 'Concombre ou produit frais',
  'Your no-sugar infusion': 'Votre infusion sans sucre',
  'Compare comfortable water temperatures as a preference experiment.':
      'Comparez des temperatures d\'eau confortables pour explorer vos preferences.',
  'Review today’s assigned temperature style.':
      'Consultez le style de temperature attribue aujourd\'hui.',
  'Use the configured amount.': 'Utilisez la quantite configuree.',
  'Log the water after drinking it.': 'Enregistrez l\'eau apres l\'avoir bue.',
  'A canonical hydration log tagged with today’s assigned temperature style.':
      'Un journal d\'hydratation canonique associe au style de temperature attribue aujourd\'hui.',
  'Water at another style still counts toward daily hydration but not this task.':
      'Une eau d\'un autre style compte pour l\'hydratation quotidienne, mais pas pour cette tache.',
  'Include one selected water-rich food in a meal without inventing hydration volume.':
      'Incluez dans un repas un aliment riche en eau sans inventer de volume d\'hydratation.',
  'Choose a meal.': 'Choisissez un repas.',
  'Choose or enter a water-rich food.':
      'Choisissez ou saisissez un aliment riche en eau.',
  'Confirm the food task after the meal.':
      'Confirmez la tache alimentaire apres le repas.',
  'One local food-task check-in on the selected day.':
      'Une confirmation locale de la tache alimentaire le jour choisi.',
  'The food check-in never creates a hydration record.':
      'La confirmation alimentaire ne cree jamais de journal d\'hydratation.',
  'Pair modest hydration check-ins with manually confirmed focus-session breaks.':
      'Associez des confirmations d\'hydratation modestes a des pauses de concentration confirmees manuellement.',
  'Complete a configured focus session.':
      'Terminez une session de concentration configuree.',
  'Wait for the sip action to unlock.':
      'Attendez que l\'action de gorgee soit disponible.',
  'Confirm Took a sip or log the measured drink after drinking.':
      'Confirmez la gorgee ou enregistrez la boisson mesuree apres l\'avoir bue.',
  'One persisted drink with the configured amount after a completed focus session.':
      'Une boisson enregistree avec la quantite configuree apres une session terminee.',
  'Timer completion and reminders never add water automatically.':
      'La fin du minuteur et les rappels n\'ajoutent jamais d\'eau automatiquement.',
  'Complete a weekly mix of explicit hydration actions and non-hydration check-ins.':
      'Terminez un melange hebdomadaire d\'actions d\'hydratation et de confirmations sans hydratation.',
  'Open a tile to review its rule.':
      'Ouvrez une tuile pour consulter sa regle.',
  'Complete the stated action.': 'Terminez l\'action indiquee.',
  'Hydration tiles log once; check-ins add no water.':
      'Les tuiles d\'hydratation enregistrent une fois; les confirmations n\'ajoutent pas d\'eau.',
  'Tile-specific canonical hydration evidence or an explicit local check-in.':
      'Une preuve d\'hydratation propre a la tuile ou une confirmation locale explicite.',
  'Unknown amounts and non-hydration tasks never create water.':
      'Les quantites inconnues et les taches sans hydratation ne creent jamais d\'eau.',
  'Use one plant-care cue as a reminder to review your hydration routine.':
      'Utilisez un signal de soin des plantes pour revoir votre routine d\'hydratation.',
  'Complete the plant-care cue.': 'Terminez le signal de soin de la plante.',
  'Confirm the cue locally.': 'Confirmez le signal localement.',
  'Log any water you actually drink separately.':
      'Enregistrez separement toute eau reellement bue.',
  'One explicit local plant-cue check-in.':
      'Une confirmation locale explicite du signal de plante.',
  'Plant care does not create a hydration record.':
      'Le soin des plantes ne cree pas de journal d\'hydratation.',
  'First Quarter': 'Premier quart',
  'Halfway Flow': 'Mi-parcours',
  'Three Quarters': 'Trois quarts',
  'Goal Day': 'Jour d\'objectif',
  'Two Moments': 'Deux moments',
  'Three Moments': 'Trois moments',
  'Four Moments': 'Quatre moments',
  'Before Lunch': 'Avant le dejeuner',
  'Morning Water': 'Eau du matin',
  'Afternoon Water': 'Eau de l\'apres-midi',
  'Planned Sip': 'Gorgee planifiee',
  'Meal-Time Drink': 'Boisson du repas',
  'Evening Sip': 'Gorgee du soir',
  'Free Drop': 'Goutte libre',
  'Refill Ready': 'Pret a remplir',
  'Flavor Prep': 'Preparation aromatisee',
  'Water-Rich Food': 'Aliment riche en eau',
  'Progress Pause': 'Pause progression',
  'Within Reach': 'A portee de main',
  'Fresh Bottle': 'Bouteille propre',
  'Tomorrow Ready': 'Pret pour demain',
  'Desk Reset': 'Pause au bureau',
  'Meal Plan': 'Plan du repas',
  'Bottle Check': 'Verification de la bouteille',
  'Gentle Break': 'Pause douce',
  'Reach 25% of today’s hydration goal.':
      'Atteignez 25 % de l\'objectif d\'hydratation du jour.',
  'Reach 50% of today’s hydration goal.':
      'Atteignez 50 % de l\'objectif d\'hydratation du jour.',
  'Reach 75% of today’s hydration goal.':
      'Atteignez 75 % de l\'objectif d\'hydratation du jour.',
  'Complete today’s hydration goal.':
      'Atteignez l\'objectif d\'hydratation du jour.',
  'Record water at two separate times today.':
      'Enregistrez de l\'eau a deux moments distincts aujourd\'hui.',
  'Record water at three separate times today.':
      'Enregistrez de l\'eau a trois moments distincts aujourd\'hui.',
  'Record water at four separate times today.':
      'Enregistrez de l\'eau a quatre moments distincts aujourd\'hui.',
  'Log water before your lunch cutoff.':
      'Enregistrez de l\'eau avant l\'heure limite du dejeuner.',
  'Log water before noon.': 'Enregistrez de l\'eau avant midi.',
  'Log water between noon and 5 PM.':
      'Enregistrez de l\'eau entre midi et 17 h.',
  'Choose and log your configured challenge amount.':
      'Choisissez et enregistrez la quantite configuree du defi.',
  'Log your configured amount with a meal.':
      'Enregistrez la quantite configuree avec un repas.',
  'A welcoming space in the center of your board.':
      'Un espace accueillant au centre de votre grille.',
  'Log your configured amount this evening if comfortable.':
      'Enregistrez la quantite configuree ce soir si cela vous convient.',
  'Refill your bottle, then check in.':
      'Remplissez votre bouteille, puis confirmez.',
  'Prepare a no-added-sugar infusion.':
      'Preparez une infusion sans sucre ajoute.',
  'Include a water-rich food with a meal.':
      'Incluez un aliment riche en eau dans un repas.',
  'Review today’s hydration progress.':
      'Consultez la progression d\'hydratation du jour.',
  'Place your bottle somewhere easy to reach.':
      'Placez votre bouteille a un endroit facile d\'acces.',
  'Clean your reusable bottle.': 'Nettoyez votre bouteille reutilisable.',
  'Plan where water will fit tomorrow.':
      'Planifiez quand boire de l\'eau demain.',
  'Refresh your water spot.': 'Rafraichissez votre espace reserve a l\'eau.',
  'Choose a meal-time hydration moment.':
      'Choisissez un moment d\'hydratation pendant un repas.',
  'Check that your bottle is ready for use.':
      'Verifiez que votre bouteille est prete a etre utilisee.',
  'Take a comfortable hydration break.':
      'Prenez une pause d\'hydratation confortable.',
  'Reminder scheduled.': 'Rappel programme.',
  'Reminder active. Android may deliver it slightly later.':
      'Rappel actif. Android peut le transmettre legerement plus tard.',
  'Waiting to be scheduled.': 'En attente de programmation.',
  'Paused.': 'En pause.',
  'Notifications are disabled. Allow them in Android settings.':
      'Les notifications sont desactivees. Autorisez-les dans les reglages Android.',
  'Reminders are unavailable on this device.':
      'Les rappels ne sont pas disponibles sur cet appareil.',
  'Choose a new time. The time has passed.':
      'Choisissez une nouvelle heure. L\'heure est passee.',
  'This reminder could not be scheduled. Please try again.':
      'Ce rappel n\'a pas pu etre programme. Reessayez.',
  'This reminder is already saved.': 'Ce rappel est deja enregistre.',
  'Reminder saved but paused.': 'Rappel enregistre mais en pause.',
  'Complete age and sex in Profile before enabling weather-informed goals.':
      'Completez l\'age et le sexe dans Profil avant d\'activer les objectifs selon la meteo.',
  'Manual goal was edited today, so Hydrion will not replace it silently.':
      'L\'objectif manuel a ete modifie aujourd\'hui; Hydrion ne le remplacera pas sans avertissement.',
  'Location access is blocked. Enable it in device settings.':
      'L\'acces a la position est bloque. Activez-le dans les reglages de l\'appareil.',
  'Allow location access to use local weather assistance.':
      'Autorisez l\'acces a la position pour utiliser l\'aide meteo locale.',
  'Turn on device location services to use weather assistance.':
      'Activez les services de localisation pour utiliser l\'aide meteo.',
  'Location lookup took too long. Check your signal and try again.':
      'La recherche de position a pris trop de temps. Verifiez le signal et reessayez.',
  'Your location is unavailable right now. Try again later.':
      'Votre position est indisponible pour le moment. Reessayez plus tard.',
  'Weather lookup took too long. Try again shortly.':
      'La recherche meteo a pris trop de temps. Reessayez bientot.',
  'Weather is unavailable while the device is offline.':
      'La meteo est indisponible lorsque l\'appareil est hors ligne.',
  'The weather service is busy right now. Try again shortly.':
      'Le service meteo est occupe. Reessayez bientot.',
  'Weather assistance is unavailable in this build.':
      'L\'aide meteo est indisponible dans cette version.',
  'Local weather is unavailable right now. Try again later.':
      'La meteo locale est indisponible pour le moment. Reessayez plus tard.',
  'Goal reached': 'Objectif atteint',
  'Goal reached. Great work listening to your routine.':
      'Objectif atteint. Beau travail en respectant votre routine.',
  'Weather-aware day': 'Journee adaptee a la meteo',
  'Warm conditions changed today\'s goal. Keep it comfortable.':
      'Les conditions chaudes ont modifie l\'objectif du jour. Restez confortable.',
  'Challenge current': 'Defi en cours',
  'Nice. That moved today and your challenge forward.':
      'Bien. Cela a fait avancer votre journee et votre defi.',
  'Gentle nudge': 'Petit rappel',
  'A small check-in now keeps the day from bunching up later.':
      'Une petite verification maintenant evite de tout regrouper plus tard.',
  'Fresh start': 'Nouveau depart',
  'Good to see you. We can start fresh with one easy log.':
      'Ravi de vous revoir. Recommencons avec un enregistrement simple.',
  'Almost there': 'Presque termine',
  'Nearly complete. Keep the finish gentle.':
      'Presque termine. Finissez en douceur.',
  'On track': 'Sur la bonne voie',
  'Halfway energy. Your routine has shape now.':
      'A mi-chemin. Votre routine prend forme.',
  'Building momentum': 'Elan en cours',
  'Nice start. A small top-up keeps the morning moving.':
      'Bon depart. Un petit complement fait avancer la matinee.',
  'Morning check-in': 'Verification du matin',
  'Let\'s make the first sip easy.':
      'Commencons par une premiere gorgee facile.',
  "Couldn't refresh everything. Your saved hydration data is still available.":
      'Impossible de tout actualiser. Vos donnees d\'hydratation enregistrees restent disponibles.',
  'Hydrion rejected an unsafe or invalid suggestion.':
      'Hydrion a refuse une suggestion dangereuse ou invalide.',
  'Your confirmation is required before Hydrion changes anything.':
      'Votre confirmation est requise avant toute modification par Hydrion.',
  'Generated guidance is ready.': 'Les conseils generes sont prets.',
  'The suggested hydration log was not applied.':
      'Le journal d\'hydratation suggere n\'a pas ete applique.',
  'Hydration log applied.': 'Journal d\'hydratation applique.',
  'Local reminder applied.': 'Rappel local applique.',
  'Local challenge applied.': 'Defi local applique.',
  'Hydrion cannot apply this suggestion.':
      'Hydrion ne peut pas appliquer cette suggestion.',
};

const _legacyChallengeSpanishText = <String, String>{
  'Try seven no-added-sugar infusion themes while maintaining your normal hydration goal.':
      'Prueba siete temas de infusion sin azucar agregada mientras mantienes tu objetivo habitual de hidratacion.',
  'Review today’s infusion theme.': 'Revisa el tema de infusion de hoy.',
  'Confirm no added sugar.': 'Confirma que no hay azucar agregada.',
  'Log the amount of infused water actually consumed.':
      'Registra la cantidad de agua infusionada que realmente consumiste.',
  'A canonical hydration log created for today’s assigned infusion theme.':
      'Un registro canonico de hidratacion creado para el tema de infusion asignado hoy.',
  'Plain water supports the daily goal but does not complete the infusion task.':
      'El agua sola contribuye al objetivo diario, pero no completa la tarea de infusion.',
  'Citrus': 'Citricos',
  'Berry': 'Bayas',
  'Tropical fruit': 'Fruta tropical',
  'Herb': 'Hierbas',
  'Fruit and herb': 'Fruta y hierbas',
  'Cucumber or fresh produce': 'Pepino o producto fresco',
  'Your no-sugar infusion': 'Tu infusion sin azucar',
  'Compare comfortable water temperatures as a preference experiment.':
      'Compara temperaturas comodas del agua para explorar tus preferencias.',
  'Review today’s assigned temperature style.':
      'Revisa el estilo de temperatura asignado hoy.',
  'Use the configured amount.': 'Usa la cantidad configurada.',
  'Log the water after drinking it.': 'Registra el agua despues de beberla.',
  'A canonical hydration log tagged with today’s assigned temperature style.':
      'Un registro canonico de hidratacion etiquetado con el estilo de temperatura asignado hoy.',
  'Water at another style still counts toward daily hydration but not this task.':
      'El agua con otro estilo cuenta para la hidratacion diaria, pero no para esta tarea.',
  'Include one selected water-rich food in a meal without inventing hydration volume.':
      'Incluye en una comida un alimento rico en agua sin inventar volumen de hidratacion.',
  'Choose a meal.': 'Elige una comida.',
  'Choose or enter a water-rich food.':
      'Elige o escribe un alimento rico en agua.',
  'Confirm the food task after the meal.':
      'Confirma la tarea de alimentos despues de la comida.',
  'One local food-task check-in on the selected day.':
      'Una confirmacion local de la tarea de alimentos el dia elegido.',
  'The food check-in never creates a hydration record.':
      'La confirmacion de alimentos nunca crea un registro de hidratacion.',
  'Pair modest hydration check-ins with manually confirmed focus-session breaks.':
      'Combina confirmaciones moderadas de hidratacion con pausas de enfoque confirmadas manualmente.',
  'Complete a configured focus session.':
      'Completa una sesion de enfoque configurada.',
  'Wait for the sip action to unlock.':
      'Espera a que se habilite la accion de sorbo.',
  'Confirm Took a sip or log the measured drink after drinking.':
      'Confirma el sorbo o registra la bebida medida despues de beberla.',
  'One persisted drink with the configured amount after a completed focus session.':
      'Una bebida guardada con la cantidad configurada despues de una sesion completada.',
  'Timer completion and reminders never add water automatically.':
      'El fin del temporizador y los recordatorios nunca agregan agua automaticamente.',
  'Complete a weekly mix of explicit hydration actions and non-hydration check-ins.':
      'Completa una combinacion semanal de acciones de hidratacion y confirmaciones sin hidratacion.',
  'Open a tile to review its rule.': 'Abre una casilla para revisar su regla.',
  'Complete the stated action.': 'Completa la accion indicada.',
  'Hydration tiles log once; check-ins add no water.':
      'Las casillas de hidratacion registran una vez; las confirmaciones no agregan agua.',
  'Tile-specific canonical hydration evidence or an explicit local check-in.':
      'Evidencia canonica de hidratacion propia de la casilla o una confirmacion local explicita.',
  'Unknown amounts and non-hydration tasks never create water.':
      'Las cantidades desconocidas y las tareas sin hidratacion nunca crean agua.',
  'Use one plant-care cue as a reminder to review your hydration routine.':
      'Usa una senal de cuidado de plantas para revisar tu rutina de hidratacion.',
  'Complete the plant-care cue.': 'Completa la senal de cuidado de la planta.',
  'Confirm the cue locally.': 'Confirma la senal localmente.',
  'Log any water you actually drink separately.':
      'Registra por separado toda el agua que realmente bebas.',
  'One explicit local plant-cue check-in.':
      'Una confirmacion local explicita de la senal de planta.',
  'Plant care does not create a hydration record.':
      'El cuidado de plantas no crea un registro de hidratacion.',
  'First Quarter': 'Primer cuarto',
  'Halfway Flow': 'Mitad del camino',
  'Three Quarters': 'Tres cuartos',
  'Goal Day': 'Dia del objetivo',
  'Two Moments': 'Dos momentos',
  'Three Moments': 'Tres momentos',
  'Four Moments': 'Cuatro momentos',
  'Before Lunch': 'Antes del almuerzo',
  'Morning Water': 'Agua matutina',
  'Afternoon Water': 'Agua de la tarde',
  'Planned Sip': 'Sorbo planificado',
  'Meal-Time Drink': 'Bebida con la comida',
  'Evening Sip': 'Sorbo nocturno',
  'Free Drop': 'Gota libre',
  'Refill Ready': 'Listo para rellenar',
  'Flavor Prep': 'Preparacion con sabor',
  'Water-Rich Food': 'Alimento rico en agua',
  'Progress Pause': 'Pausa de progreso',
  'Within Reach': 'Al alcance',
  'Fresh Bottle': 'Botella limpia',
  'Tomorrow Ready': 'Listo para manana',
  'Desk Reset': 'Pausa en el escritorio',
  'Meal Plan': 'Plan de comida',
  'Bottle Check': 'Revision de botella',
  'Gentle Break': 'Pausa suave',
  'Reach 25% of today’s hydration goal.':
      'Alcanza el 25 % del objetivo de hidratacion de hoy.',
  'Reach 50% of today’s hydration goal.':
      'Alcanza el 50 % del objetivo de hidratacion de hoy.',
  'Reach 75% of today’s hydration goal.':
      'Alcanza el 75 % del objetivo de hidratacion de hoy.',
  'Complete today’s hydration goal.':
      'Completa el objetivo de hidratacion de hoy.',
  'Record water at two separate times today.':
      'Registra agua en dos momentos distintos hoy.',
  'Record water at three separate times today.':
      'Registra agua en tres momentos distintos hoy.',
  'Record water at four separate times today.':
      'Registra agua en cuatro momentos distintos hoy.',
  'Log water before your lunch cutoff.':
      'Registra agua antes de la hora limite del almuerzo.',
  'Log water before noon.': 'Registra agua antes del mediodia.',
  'Log water between noon and 5 PM.':
      'Registra agua entre el mediodia y las 5 p. m.',
  'Choose and log your configured challenge amount.':
      'Elige y registra la cantidad configurada del reto.',
  'Log your configured amount with a meal.':
      'Registra la cantidad configurada con una comida.',
  'A welcoming space in the center of your board.':
      'Un espacio acogedor en el centro de tu tablero.',
  'Log your configured amount this evening if comfortable.':
      'Registra la cantidad configurada esta noche si te resulta comodo.',
  'Refill your bottle, then check in.': 'Rellena tu botella y luego confirma.',
  'Prepare a no-added-sugar infusion.':
      'Prepara una infusion sin azucar agregada.',
  'Include a water-rich food with a meal.':
      'Incluye un alimento rico en agua con una comida.',
  'Review today’s hydration progress.':
      'Revisa el progreso de hidratacion de hoy.',
  'Place your bottle somewhere easy to reach.':
      'Coloca tu botella en un lugar facil de alcanzar.',
  'Clean your reusable bottle.': 'Limpia tu botella reutilizable.',
  'Plan where water will fit tomorrow.': 'Planifica cuando beber agua manana.',
  'Refresh your water spot.': 'Renueva tu espacio para el agua.',
  'Choose a meal-time hydration moment.':
      'Elige un momento de hidratacion durante una comida.',
  'Check that your bottle is ready for use.':
      'Comprueba que tu botella este lista para usar.',
  'Take a comfortable hydration break.':
      'Toma una pausa de hidratacion comoda.',
  'Reminder scheduled.': 'Recordatorio programado.',
  'Reminder active. Android may deliver it slightly later.':
      'Recordatorio activo. Android puede entregarlo un poco mas tarde.',
  'Waiting to be scheduled.': 'Esperando programacion.',
  'Paused.': 'En pausa.',
  'Notifications are disabled. Allow them in Android settings.':
      'Las notificaciones estan desactivadas. Permiteles acceso en los ajustes de Android.',
  'Reminders are unavailable on this device.':
      'Los recordatorios no estan disponibles en este dispositivo.',
  'Choose a new time. The time has passed.':
      'Elige una hora nueva. La hora ya paso.',
  'This reminder could not be scheduled. Please try again.':
      'No se pudo programar este recordatorio. Intentalo de nuevo.',
  'This reminder is already saved.': 'Este recordatorio ya esta guardado.',
  'Reminder saved but paused.': 'Recordatorio guardado pero en pausa.',
  'Complete age and sex in Profile before enabling weather-informed goals.':
      'Completa la edad y el sexo en Perfil antes de activar objetivos segun el clima.',
  'Manual goal was edited today, so Hydrion will not replace it silently.':
      'El objetivo manual se edito hoy; Hydrion no lo reemplazara sin avisar.',
  'Location access is blocked. Enable it in device settings.':
      'El acceso a la ubicacion esta bloqueado. Activalo en los ajustes del dispositivo.',
  'Allow location access to use local weather assistance.':
      'Permite el acceso a la ubicacion para usar la ayuda meteorologica local.',
  'Turn on device location services to use weather assistance.':
      'Activa los servicios de ubicacion para usar la ayuda meteorologica.',
  'Location lookup took too long. Check your signal and try again.':
      'La busqueda de ubicacion tardo demasiado. Comprueba la senal e intentalo de nuevo.',
  'Your location is unavailable right now. Try again later.':
      'Tu ubicacion no esta disponible ahora. Intentalo mas tarde.',
  'Weather lookup took too long. Try again shortly.':
      'La consulta del clima tardo demasiado. Intentalo pronto.',
  'Weather is unavailable while the device is offline.':
      'El clima no esta disponible mientras el dispositivo esta sin conexion.',
  'The weather service is busy right now. Try again shortly.':
      'El servicio meteorologico esta ocupado. Intentalo pronto.',
  'Weather assistance is unavailable in this build.':
      'La ayuda meteorologica no esta disponible en esta version.',
  'Local weather is unavailable right now. Try again later.':
      'El clima local no esta disponible ahora. Intentalo mas tarde.',
  'Goal reached': 'Objetivo alcanzado',
  'Goal reached. Great work listening to your routine.':
      'Objetivo alcanzado. Buen trabajo respetando tu rutina.',
  'Weather-aware day': 'Dia adaptado al clima',
  'Warm conditions changed today\'s goal. Keep it comfortable.':
      'El clima calido cambio el objetivo de hoy. Mantenlo comodo.',
  'Challenge current': 'Reto en curso',
  'Nice. That moved today and your challenge forward.':
      'Bien. Eso hizo avanzar tu dia y tu reto.',
  'Gentle nudge': 'Recordatorio suave',
  'A small check-in now keeps the day from bunching up later.':
      'Una pequena revision ahora evita acumular todo mas tarde.',
  'Fresh start': 'Nuevo comienzo',
  'Good to see you. We can start fresh with one easy log.':
      'Que bueno verte. Empecemos de nuevo con un registro sencillo.',
  'Almost there': 'Casi terminado',
  'Nearly complete. Keep the finish gentle.':
      'Casi terminado. Completa con calma.',
  'On track': 'En camino',
  'Halfway energy. Your routine has shape now.':
      'A mitad de camino. Tu rutina ya toma forma.',
  'Building momentum': 'Ganando impulso',
  'Nice start. A small top-up keeps the morning moving.':
      'Buen comienzo. Un pequeno aporte mantiene la manana en marcha.',
  'Morning check-in': 'Revision matutina',
  'Let\'s make the first sip easy.': 'Hagamos facil el primer sorbo.',
  "Couldn't refresh everything. Your saved hydration data is still available.":
      'No se pudo actualizar todo. Tus datos de hidratacion guardados siguen disponibles.',
  'Hydrion rejected an unsafe or invalid suggestion.':
      'Hydrion rechazo una sugerencia insegura o no valida.',
  'Your confirmation is required before Hydrion changes anything.':
      'Se requiere tu confirmacion antes de que Hydrion cambie algo.',
  'Generated guidance is ready.': 'La orientacion generada esta lista.',
  'The suggested hydration log was not applied.':
      'No se aplico el registro de hidratacion sugerido.',
  'Hydration log applied.': 'Registro de hidratacion aplicado.',
  'Local reminder applied.': 'Recordatorio local aplicado.',
  'Local challenge applied.': 'Reto local aplicado.',
  'Hydrion cannot apply this suggestion.':
      'Hydrion no puede aplicar esta sugerencia.',
};

extension HydrionChallengeLocalizations on AppLocalizations {
  bool get _challengeFrench => localeName.toLowerCase().startsWith('fr');
  bool get _challengeSpanish => localeName.toLowerCase().startsWith('es');

  String challengeText(String english) {
    if (_challengeFrench) {
      return _challengeFrenchText[english] ??
          _legacyChallengeFrenchText[english] ??
          english;
    }
    if (_challengeSpanish) {
      return _challengeSpanishText[english] ??
          _legacyChallengeSpanishText[english] ??
          english;
    }
    return english;
  }

  String challengeNumbered(int number, String text) => '$number. $text';

  String challengeActiveStatus(int day, int duration) => _challengeFrench
      ? 'Actif · Jour $day sur $duration'
      : _challengeSpanish
          ? 'Activo · Dia $day de $duration'
          : 'Active · Day $day of $duration';

  String challengeCompletedStatus(int duration) => _challengeFrench
      ? 'Termine · $duration jours'
      : _challengeSpanish
          ? 'Completado · $duration dias'
          : 'Completed · $duration days';

  String challengeProgressSummary(int completed, int duration, int checkIns) {
    if (_challengeFrench) {
      return '$completed jours termines sur $duration. ${checkIns == 0 ? 'Aucune confirmation pour le moment.' : '$checkIns confirmations terminees.'}';
    }
    if (_challengeSpanish) {
      return '$completed de $duration dias completados. ${checkIns == 0 ? 'Aun no hay confirmaciones.' : '$checkIns confirmaciones completadas.'}';
    }
    return '$completed of $duration days completed. ${checkIns == 0 ? 'No check-ins yet.' : '$checkIns check-ins completed.'}';
  }

  String challengeActivityProgress(int completed, int total) => _challengeFrench
      ? '$completed checkpoints termines sur $total aujourd\'hui'
      : _challengeSpanish
          ? '$completed de $total puntos completados hoy'
          : '$completed of $total checkpoints complete today';

  String challengeActivitySemantics(
          String status, String elapsed, String statusLabel) =>
      _challengeFrench
          ? 'Session d\'activite $statusLabel, $elapsed ecoule'
          : _challengeSpanish
              ? 'Sesion de actividad $statusLabel, $elapsed transcurrido'
              : '$status activity session, $elapsed elapsed';

  String challengeCheckpointSemantics(String title, String state) =>
      '$title. ${challengeText(state)}';

  String challengeCompleteCheckpoint(String title) => _challengeFrench
      ? 'Terminer ${title.toLowerCase()}'
      : _challengeSpanish
          ? 'Completar ${title.toLowerCase()}'
          : 'Complete ${title.toLowerCase()}';

  String challengeCheckpointCompleted(String title) => _challengeFrench
      ? '$title termine.'
      : _challengeSpanish
          ? '$title completado.'
          : '$title completed.';

  String challengeFocusTimerTitle(int session, int planned) => _challengeFrench
      ? 'Minuteur de concentration · Session $session sur $planned'
      : _challengeSpanish
          ? 'Temporizador de concentracion · Sesion $session de $planned'
          : 'Focus timer · Session $session of $planned';

  String challengeFocusRemaining(String minutes, String seconds) =>
      _challengeFrench
          ? '$minutes minutes et $seconds secondes restantes'
          : _challengeSpanish
              ? '$minutes minutos y $seconds segundos restantes'
              : '$minutes minutes $seconds seconds remaining';

  String challengeFocusProgress(int percent) => _challengeFrench
      ? '$percent pour cent de la session de concentration terminee'
      : _challengeSpanish
          ? '$percent por ciento de la sesion de concentracion completada'
          : '$percent percent of the focus session complete';

  String challengeIllustrationSemantics(String name) => _challengeFrench
      ? 'Illustration de $name'
      : _challengeSpanish
          ? 'Ilustracion de $name'
          : '$name illustration';

  String challengeBingoCompletion(int tiles, int lines) => _challengeFrench
      ? 'Vous avez termine $tiles tuiles et $lines ${lines == 1 ? 'ligne' : 'lignes'} de Bingo.'
      : _challengeSpanish
          ? 'Completaste $tiles casillas y $lines ${lines == 1 ? 'linea' : 'lineas'} de Bingo.'
          : 'You completed $tiles tiles and $lines Bingo ${lines == 1 ? 'line' : 'lines'}.';

  String challengeTemperatureCompletion(int days) => _challengeFrench
      ? 'Vous avez termine $days jours de styles de temperature attribues.'
      : _challengeSpanish
          ? 'Completaste $days dias de estilos de temperatura asignados.'
          : 'You completed $days days of assigned temperature styles.';

  String challengePomodoroCompletion(int checkIns) => _challengeFrench
      ? 'Vous avez termine les sessions de concentration et enregistre $checkIns confirmations de gorgee.'
      : _challengeSpanish
          ? 'Completaste las sesiones de concentracion y registraste $checkIns confirmaciones de sorbos.'
          : 'You completed focus sessions and recorded $checkIns sip check-ins.';

  String challengeTemperatureAssigned(String assigned) => _challengeFrench
      ? 'La temperature attribuee aujourd\'hui est $assigned'
      : _challengeSpanish
          ? 'La temperatura asignada hoy es $assigned'
          : "Today's assigned temperature is $assigned";

  String challengeTodayTheme(String theme) => _challengeFrench
      ? 'Theme du jour: $theme'
      : _challengeSpanish
          ? 'Tema de hoy: $theme'
          : "Today's theme: $theme";

  String challengeScheduleItem(int day, String item) => _challengeFrench
      ? 'Jour $day: $item'
      : _challengeSpanish
          ? 'Dia $day: $item'
          : 'Day $day: $item';

  String challengeMealInstruction(String? meal) => _challengeFrench
      ? meal != null
          ? 'Ajoutez-le a $meal. La tache alimentaire et l\'hydratation restent separees; seules les boissons enregistrees modifient l\'hydratation.'
          : 'Incluez-le dans un repas ou une collation. La tache alimentaire et l\'hydratation restent separees; seules les boissons enregistrees modifient l\'hydratation.'
      : _challengeSpanish
          ? meal != null
              ? 'Agregalo a $meal. La tarea de alimentos y la hidratacion permanecen separadas; solo las bebidas registradas cambian la hidratacion.'
              : 'Incluyelo en una comida o merienda. La tarea de alimentos y la hidratacion permanecen separadas; solo las bebidas registradas cambian la hidratacion.'
          : meal != null
              ? 'Add it to $meal. Food completion and fluid hydration stay separate; only drinks you log change hydration.'
              : 'Include it with a meal or snack. Food completion and fluid hydration stay separate; only drinks you log change hydration.';

  String challengeInfusionInstruction(String? amount) => _challengeFrench
      ? amount != null
          ? 'Preparez sans sucre ajoute et enregistrez $amount apres l\'avoir bu.'
          : 'Preparez sans sucre ajoute et enregistrez uniquement ce que vous buvez.'
      : _challengeSpanish
          ? amount != null
              ? 'Prepara sin azucar agregada y registra $amount despues de beberlo.'
              : 'Prepara sin azucar agregada y registra solo lo que bebas.'
          : amount != null
              ? 'Prepare without added sugar and log $amount after drinking it.'
              : 'Prepare without added sugar and log only what you drink.';

  String challengeBingoHeroProgress(int tiles, int lines,
          {required bool compact}) =>
      _challengeFrench
          ? compact
              ? '$tiles/25 tuiles · $lines/12 lignes'
              : '$tiles tuiles sur 25 · $lines lignes sur 12'
          : _challengeSpanish
              ? compact
                  ? '$tiles/25 casillas · $lines/12 lineas'
                  : '$tiles de 25 casillas · $lines de 12 lineas'
              : compact
                  ? '$tiles/25 tiles · $lines/12 lines'
                  : '$tiles of 25 tiles · $lines of 12 lines';

  String challengeBingoMetricsSemantics(int tiles, int lines, String today) =>
      _challengeFrench
          ? '$tiles tuiles sur 25, $lines lignes sur 12, $today aujourd\'hui'
          : _challengeSpanish
              ? '$tiles de 25 casillas, $lines de 12 lineas, $today hoy'
              : '$tiles of 25 tiles, $lines of 12 lines, $today today';

  String challengeBingoTileSemantics(String title, String status, String detail,
      bool inLine, bool actionable) {
    final line = inLine ? challengeText('Part of a completed Bingo line.') : '';
    final action = actionable ? challengeText('Double tap for details.') : '';
    return '$title. $status. $detail. $line $action'.trim();
  }

  String challengeBingoDetailsSemantics(String title) => _challengeFrench
      ? 'Details de $title'
      : _challengeSpanish
          ? 'Detalles de $title'
          : '$title details';

  String challengeLogAmount(String amount) => _challengeFrench
      ? 'Enregistrer $amount'
      : _challengeSpanish
          ? 'Registrar $amount'
          : 'Log $amount';

  String challengeMatchesTemperature(String temperature) => _challengeFrench
      ? 'Correspond a la temperature $temperature d\'aujourd\'hui'
      : _challengeSpanish
          ? 'Coincide con la temperatura $temperature de hoy'
          : 'Matches today’s $temperature temperature';

  String challengeMatchesInfusion(String infusion) => _challengeFrench
      ? 'Infusion $infusion sans sucre ajoute'
      : _challengeSpanish
          ? 'Infusion $infusion sin azucar agregada'
          : '$infusion infusion with no added sugar';

  String challengeInfusionDailyInstruction(String theme, String amount) => _challengeFrench
      ? 'Theme du jour: $theme. Confirmez l\'absence de sucre ajoute et enregistrez la quantite reelle consommee: $amount.'
      : _challengeSpanish
          ? 'Tema de hoy: $theme. Confirma que no hay azucar agregada y registra la cantidad real consumida: $amount.'
          : "Today's theme: $theme. Confirm no added sugar and log the actual $amount consumed.";

  String challengeTemperatureDailyInstruction(
          String style, String amount, String weather) =>
      _challengeFrench
          ? 'Style attribue aujourd\'hui: $style. Enregistrez $amount. $weather'
          : _challengeSpanish
              ? 'Estilo asignado hoy: $style. Registra $amount. $weather'
              : "Today's assigned style: $style. Log $amount. $weather";

  String challengeFoodDailyInstruction(String food, String meal) =>
      _challengeFrench
          ? 'Incluez $food avec $meal, puis confirmez la tache alimentaire.'
          : _challengeSpanish
              ? 'Incluye $food con $meal y confirma la tarea de alimentos.'
              : 'Include $food with $meal, then confirm the food task.';

  String challengePomodoroDailyInstruction(int minutes, String amount) => _challengeFrench
      ? 'Apres chaque session de concentration de $minutes minutes, confirmez une gorgee ou enregistrez une boisson mesuree de $amount.'
      : _challengeSpanish
          ? 'Despues de cada sesion de concentracion de $minutes minutos, confirma un sorbo o registra una bebida medida de $amount.'
          : 'After each $minutes-minute focus session, choose Took a sip for a check-in or log a measured $amount drink.';

  String challengeCueDailyInstruction(String cue) => _challengeFrench
      ? 'Effectuez le signal $cue aujourd\'hui, puis confirmez-le. Enregistrez l\'eau mesuree separement.'
      : _challengeSpanish
          ? 'Completa hoy la senal $cue y luego confirmala. Registra el agua medida por separado.'
          : 'Complete today’s $cue cue, then mark it complete. Log measured water separately.';

  String sharedTourStep(int current, int total) => _challengeFrench
      ? 'Etape $current sur $total'
      : _challengeSpanish
          ? 'Paso $current de $total'
          : 'Step $current of $total';

  String sharedHydrationRecorded(String amount, int count) => _challengeFrench
      ? '$amount enregistres dans $count ${count == 1 ? 'entree' : 'entrees'} aujourd\'hui.'
      : _challengeSpanish
          ? '$amount registrados en $count ${count == 1 ? 'entrada' : 'entradas'} hoy.'
          : '$amount recorded across $count ${count == 1 ? 'log' : 'logs'} today.';

  String sharedHydrationStatus(
          String recorded, String? remaining, bool complete) =>
      complete
          ? _challengeFrench
              ? 'Objectif quotidien atteint. $recorded'
              : _challengeSpanish
                  ? 'Objetivo diario completado. $recorded'
                  : 'Daily goal completed. $recorded'
          : _challengeFrench
              ? '$recorded Il reste $remaining.'
              : _challengeSpanish
                  ? '$recorded Quedan $remaining.'
                  : '$recorded $remaining remaining.';

  String sharedGaugeSemantics(
          int percent, String consumed, String goal, String status) =>
      _challengeFrench
          ? 'Indicateur de progression de l\'hydratation, $percent pour cent. $consumed consommes sur un objectif quotidien de $goal. $status.'
          : _challengeSpanish
              ? 'Indicador de progreso de hidratacion, $percent por ciento. $consumed consumidos de un objetivo diario de $goal. $status.'
              : 'Hydration progress gauge, $percent percent. $consumed consumed of $goal daily goal. $status.';

  String sharedPercent(int percent) => _challengeFrench
      ? '$percent pour cent'
      : _challengeSpanish
          ? '$percent por ciento'
          : '$percent percent';

  String sharedTodaysHydrationProgress(String current, String target) =>
      _challengeFrench
          ? 'Hydratation aujourd\'hui : $current / $target'
          : _challengeSpanish
              ? 'Hidratacion de hoy: $current / $target'
              : "Today's hydration: $current / $target";

  String sharedWeeklyHydrationEmpty() => _challengeFrench
      ? 'Aucune hydratation enregistree au cours des 7 derniers jours.'
      : _challengeSpanish
          ? 'No se registro hidratacion en los ultimos 7 dias.'
          : 'No hydration recorded in the last 7 days.';

  String sharedWeeklyHydrationAverage(String average, String target) =>
      _challengeFrench
          ? 'Moyenne quotidienne : $average. Objectif : $target.'
          : _challengeSpanish
              ? 'Promedio diario: $average. Objetivo: $target.'
              : '$average daily average. Target: $target.';

  String sharedWeeklyHydrationChart(String entries) => _challengeFrench
      ? 'Graphique d\'hydratation sur sept jours. $entries.'
      : _challengeSpanish
          ? 'Grafico de hidratacion de siete dias. $entries.'
          : 'Seven day hydration chart. $entries.';

  String sharedDayHydration(String date, String amount,
          {required bool isToday}) =>
      isToday
          ? _challengeFrench
              ? '$date, $amount, aujourd\'hui'
              : _challengeSpanish
                  ? '$date, $amount, hoy'
                  : '$date, $amount, today'
          : '$date, $amount';

  String sharedValueUpdated(String value, String updated) => '$value\n$updated';

  String sharedBmiCalculation(
          String weight, String weightUnit, int height, String heightUnit) =>
      _challengeFrench
          ? 'Calcule a partir de $weight $weightUnit et $height $heightUnit.'
          : _challengeSpanish
              ? 'Calculado a partir de $weight $weightUnit y $height $heightUnit.'
              : 'Calculated from $weight $weightUnit and $height $heightUnit.';

  String sharedAdjustments(String label, int amount) => _challengeFrench
      ? '$label : $amount ml'
      : _challengeSpanish
          ? '$label: $amount ml'
          : '$label: $amount mL';

  String sharedHistoryStatus(String status, String date) =>
      '$status \u00b7 $date';

  String sharedDailyTarget(String amount) => _challengeFrench
      ? '$amount/jour'
      : _challengeSpanish
          ? '$amount/dia'
          : '$amount/day';

  String sharedChallengeHydration(String amount) => _challengeFrench
      ? 'Hydratation du defi aujourd\'hui : $amount'
      : _challengeSpanish
          ? 'Hidratacion del reto de hoy: $amount'
          : "Today's challenge hydration: $amount";

  String sharedChallengeDays(int completed, int total) => _challengeFrench
      ? '$completed/$total jours confirmes'
      : _challengeSpanish
          ? '$completed/$total dias confirmados'
          : '$completed/$total days checked in';

  String sharedPomodoroProgress(
          int completed, int total, int checkIns, String measured) =>
      _challengeFrench
          ? '$completed/$total jours \u00b7 $checkIns confirmations de gorgee \u00b7 $measured mesures'
          : _challengeSpanish
              ? '$completed/$total dias \u00b7 $checkIns confirmaciones de sorbos \u00b7 $measured medidos'
              : '$completed/$total days \u00b7 $checkIns sip check-ins \u00b7 $measured measured';

  String sharedAvatarRelationship(String name) => _challengeFrench
      ? '$name est votre compagnon requin.'
      : _challengeSpanish
          ? '$name es tu companero tiburon.'
          : '$name is your shark companion.';

  String sharedActiveChallengeCount(int count) => _challengeFrench
      ? '$count ${count == 1 ? 'defi actif' : 'defis actifs'}'
      : _challengeSpanish
          ? '$count ${count == 1 ? 'reto activo' : 'retos activos'}'
          : '$count active ${count == 1 ? 'challenge' : 'challenges'}';

  String sharedOpenChallengeDetails(String title) => _challengeFrench
      ? '$title. Ouvrir les details du defi.'
      : _challengeSpanish
          ? '$title. Abrir detalles del reto.'
          : '$title. Open challenge details.';

  String sharedTodayHydration(String amount) => _challengeFrench
      ? 'Hydratation totale aujourd\'hui: $amount'
      : _challengeSpanish
          ? 'Hidratacion total de hoy: $amount'
          : "Today's total hydration: $amount";

  LocalizedChallengeCopy challengeCopy(String id) => switch (id) {
        'around-the-world-infusion-week' => LocalizedChallengeCopy(
            title: challengeAroundWorldTitle,
            description: challengeAroundWorldDescription,
          ),
        'temperature-roulette' => LocalizedChallengeCopy(
            title: challengeTemperatureTitle,
            description: challengeTemperatureDescription,
          ),
        'eat-your-water-day' => LocalizedChallengeCopy(
            title: challengeEatWaterTitle,
            description: challengeEatWaterDescription,
          ),
        'pomodoro-sip' => LocalizedChallengeCopy(
            title: challengePomodoroTitle,
            description: challengePomodoroDescription,
          ),
        'plant-twin-challenge' => LocalizedChallengeCopy(
            title: challengePlantTwinTitle,
            description: challengePlantTwinDescription,
          ),
        'bottle-bingo' => LocalizedChallengeCopy(
            title: challengeBottleBingoTitle,
            description: challengeBottleBingoDescription,
          ),
        'lunch-break-refill' => LocalizedChallengeCopy(
            title: challengeLunchRefillTitle,
            description: challengeLunchRefillDescription,
          ),
        'homework-hydration' => LocalizedChallengeCopy(
            title: challengeHomeworkTitle,
            description: challengeHomeworkDescription,
          ),
        'after-school-recharge' => LocalizedChallengeCopy(
            title: challengeAfterSchoolTitle,
            description: challengeAfterSchoolDescription,
          ),
        'backpack-bottle-check' => LocalizedChallengeCopy(
            title: challengeBackpackTitle,
            description: challengeBackpackDescription,
          ),
        'desk-day-reset' => LocalizedChallengeCopy(
            title: challengeDeskResetTitle,
            description: challengeDeskResetDescription,
          ),
        'shift-hydration-check' => LocalizedChallengeCopy(
            title: challengeShiftCheckTitle,
            description: challengeShiftCheckDescription,
          ),
        'commute-cup' => LocalizedChallengeCopy(
            title: challengeCommuteCupTitle,
            description: challengeCommuteCupDescription,
          ),
        'evening-goal-review' => LocalizedChallengeCopy(
            title: challengeEveningReviewTitle,
            description: challengeEveningReviewDescription,
          ),
        _ => LocalizedChallengeCopy(
            title: challengesTitle,
            description: noChallengesAvailable,
          ),
      };
}

const _challengeFrenchText = <String, String>{
  'Complete setup': 'Terminer la configuration',
  'Join challenge': 'Rejoindre le defi',
  'Pause or leave one challenge first':
      'Mettez d\'abord un defi en pause ou quittez-le',
  'You already have two active challenges. Pause or leave one before starting another.':
      'Vous avez deja deux defis actifs. Mettez-en un en pause ou quittez-le avant d\'en commencer un autre.',
  'Continue': 'Continuer',
  'Set up challenge': 'Configurer le defi',
  'Challenge paused': 'Defi en pause',
  'Your progress and hydration history are safe. This challenge is not evaluating new hydration while paused.':
      'Votre progression et votre historique d\'hydratation sont conserves. Ce defi n\'evalue pas les nouvelles donnees d\'hydratation pendant la pause.',
  'Pause or leave an active challenge before resuming this one.':
      'Mettez un defi actif en pause ou quittez-le avant de reprendre celui-ci.',
  'Resume challenge': 'Reprendre le defi',
  'Leave challenge': 'Quitter le defi',
  'Challenge complete': 'Defi termine',
  'Measured hydration contribution': 'Contribution d\'hydratation mesuree',
  'Repeat challenge': 'Refaire le defi',
  'Explore another challenge': 'Explorer un autre defi',
  'Close': 'Fermer',
  "Today's instruction": 'Instruction du jour',
  "Today's parameters": 'Parametres du jour',
  "Today's hydration toward your current daily goal":
      'Hydratation du jour par rapport a votre objectif quotidien actuel',
  'Challenge-qualified hydration': 'Hydratation admissible au defi',
  'Challenge progress': 'Progression du defi',
  'History': 'Historique',
  'Challenge settings': 'Parametres du defi',
  'Small preferences can apply now or tomorrow. Schedule changes begin with the next activity, while your hydration history stays intact.':
      'Les petites preferences peuvent s\'appliquer maintenant ou demain. Les changements d\'horaire commencent a la prochaine activite, tandis que votre historique d\'hydratation reste intact.',
  'How it works': 'Fonctionnement',
  'Edit challenge settings': 'Modifier les parametres du defi',
  'Pause': 'Pause',
  'Recent activity': 'Activite recente',
  'See all activity': 'Voir toute l\'activite',
  'Replay board guide': 'Revoir le guide du tableau',
  'Pause or leave this challenge from the options menu above. Your hydration records remain intact.':
      'Mettez ce defi en pause ou quittez-le depuis le menu ci-dessus. Vos donnees d\'hydratation restent intactes.',
  'Bottle Bingo activity': 'Activite Bottle Bingo',
  'Choose a smaller sip amount or fewer sessions so the plan does not exceed your normal goal.':
      'Choisissez une plus petite quantite ou moins de sessions afin que le plan ne depasse pas votre objectif normal.',
  'Complete this focus session before confirming your sip.':
      'Terminez cette session de concentration avant de confirmer votre gorgee.',
  'That sip was already recorded or could not be saved. Check your history before trying again.':
      'Cette gorgee a deja ete enregistree ou n\'a pas pu etre sauvegardee. Verifiez votre historique avant de reessayer.',
  'Log water normally; qualifying records update this challenge automatically.':
      'Enregistrez l\'eau normalement; les entrees admissibles mettent ce defi a jour automatiquement.',
  'Complete the focus session first, or check whether this drink was already recorded.':
      'Terminez d\'abord la session de concentration ou verifiez si cette boisson a deja ete enregistree.',
  'Add drink details': 'Ajouter les details de la boisson',
  'The measured drink counts once. Confirm only details that apply so another active challenge can recognize it.':
      'La boisson mesuree compte une seule fois. Confirmez uniquement les details applicables afin qu\'un autre defi actif puisse la reconnaitre.',
  'Cancel': 'Annuler',
  'Log measured drink': 'Enregistrer la boisson mesuree',
  'Challenge complete. Your steady effort counted.':
      'Defi termine. Votre effort regulier a compte.',
  'Review qualifying rule': 'Verifier la regle d\'admissibilite',
  'Session notifications': 'Notifications de session',
  'Applies immediately': 'S\'applique immediatement',
  'Future serving amount': 'Quantite des prochaines portions',
  'Applies next local day. Today’s progress stays the same.':
      'S\'applique au prochain jour local. La progression d\'aujourd\'hui reste identique.',
  'Restart challenge attempt': 'Recommencer la tentative',
  'Keeps hydration history and starts challenge progress again.':
      'Conserve l\'historique d\'hydratation et recommence la progression du defi.',
  'This change starts tomorrow. Today’s progress will stay the same.':
      'Ce changement commence demain. La progression d\'aujourd\'hui restera identique.',
  'Save for tomorrow': 'Enregistrer pour demain',
  'Restart this challenge?': 'Recommencer ce defi?',
  'Restarting creates a new challenge attempt. Your hydration history will remain, but this challenge’s progress will begin again.':
      'Recommencer cree une nouvelle tentative. Votre historique d\'hydratation sera conserve, mais la progression de ce defi repartira de zero.',
  'Keep current attempt': 'Conserver la tentative actuelle',
  'Restart': 'Recommencer',
  'A new challenge attempt has started.': 'Une nouvelle tentative a commence.',
  'That change could not be saved.':
      'Ce changement n\'a pas pu etre enregistre.',
  'Change applied.': 'Changement applique.',
  'The challenge could not be restarted.':
      'Le defi n\'a pas pu etre recommence.',
  'This setting cannot be changed while the challenge is active.':
      'Ce reglage ne peut pas etre modifie pendant que le defi est actif.',
  'Leave this challenge?': 'Quitter ce defi?',
  'Your hydration history stays intact. Challenge setup and unfinished task progress will be removed.':
      'Votre historique d\'hydratation reste intact. La configuration et la progression des taches inachevees seront supprimees.',
  'Keep challenge': 'Conserver le defi',
  'Pause this challenge?': 'Mettre ce defi en pause?',
  'Progress and hydration history will stay. New hydration will not qualify until you resume.':
      'La progression et l\'historique d\'hydratation seront conserves. La nouvelle hydratation ne sera pas admissible avant la reprise.',
  'Keep active': 'Garder actif',
  'Leave this paused challenge?': 'Quitter ce defi en pause?',
  'Hydration history stays. This attempt will remain in challenge history.':
      'L\'historique d\'hydratation est conserve. Cette tentative restera dans l\'historique du defi.',
  'Keep paused': 'Garder en pause',
  'Leave': 'Quitter',
  'You completed the infusion themes in this attempt.':
      'Vous avez termine les themes d\'infusion de cette tentative.',
  'You completed the water-rich food task.':
      'Vous avez termine la tache des aliments riches en eau.',
  'You completed this Bottle Bingo board.':
      'Vous avez termine ce tableau Bottle Bingo.',
  'You completed this challenge attempt.':
      'Vous avez termine cette tentative de defi.',
  'Current activity': 'Activite actuelle',
  'Start activity': 'Demarrer l\'activite',
  'Resume': 'Reprendre',
  'Open normal drink logging': 'Ouvrir le journal normal des boissons',
  'Opening drink logging does not complete this activity or add water.':
      'Ouvrir le journal des boissons ne termine pas cette activite et n\'ajoute pas d\'eau.',
  'Completed': 'Termine',
  'Available': 'Disponible',
  'Waiting': 'En attente',
  'Ready': 'Pret',
  'Packed': 'Range',
  'Needs attention': 'Necessite une verification',
  'Bottle checked': 'Bouteille verifiee',
  'Refilled': 'Remplie',
  'Today’s challenge activity is complete.':
      'L\'activite du defi est terminee pour aujourd\'hui.',
  'Active': 'Active',
  'Paused': 'En pause',
  'Focus session complete': 'Session de concentration terminee',
  'Focus session complete. Take your planned sip when you are ready.':
      'Session de concentration terminee. Prenez la gorgee prevue lorsque vous etes pret.',
  'Sip ready': 'Gorgee prete',
  'Start next focus session': 'Demarrer la prochaine session',
  'Restart session': 'Recommencer la session',
  'End early': 'Terminer plus tot',
  'Stop today’s plan': 'Arreter le plan d\'aujourd\'hui',
  'Focus session complete. No water has been added. Confirm Took a sip or log a measured drink when you actually drink.':
      'Session de concentration terminee. Aucune eau n\'a ete ajoutee. Confirmez une gorgee ou enregistrez une boisson mesuree lorsque vous buvez vraiment.',
  'A flexible lunch-window bottle check.':
      'Une verification flexible de la bouteille pendant la pause dejeuner.',
  'Check your bottle': 'Verifier votre bouteille',
  'Confirm that you checked it. Refill only when that is useful.':
      'Confirmez que vous l\'avez verifiee. Remplissez-la seulement si cela est utile.',
  'A private study session with deliberate checkpoints.':
      'Une session d\'etude privee avec des checkpoints deliberes.',
  'Hydration check': 'Verification de l\'hydratation',
  'Review your hydration when the checkpoint is available.':
      'Verifiez votre hydratation lorsque le checkpoint est disponible.',
  'Finish the session': 'Terminer la session',
  'Deliberately finish after reviewing the session checkpoint.':
      'Terminez deliberement apres avoir verifie le checkpoint de la session.',
  'A neutral afternoon recharge window.':
      'Une periode neutre de recharge dans l\'apres-midi.',
  'Review current progress': 'Verifier la progression actuelle',
  'Look at today’s hydration progress without pressure.':
      'Consultez la progression d\'hydratation du jour sans pression.',
  'Prepare water': 'Preparer de l\'eau',
  'Prepare water if it is useful for the rest of the day.':
      'Preparez de l\'eau si cela est utile pour le reste de la journee.',
  'Finish recharge routine': 'Terminer la routine de recharge',
  'Confirm the short routine is complete.':
      'Confirmez que la courte routine est terminee.',
  'A private reusable-bottle preparation cue.':
      'Un signal prive de preparation d\'une bouteille reutilisable.',
  'Record bottle status': 'Enregistrer l\'etat de la bouteille',
  'Choose ready, packed, or needs attention.':
      'Choisissez pret, range ou necessite une verification.',
  'A flexible seated-work reset routine.':
      'Une routine flexible de remise a zero pour le travail assis.',
  'Movement or posture reset': 'Pause mouvement ou posture',
  'Complete one comfortable reset away from the screen.':
      'Effectuez une pause confortable loin de l\'ecran.',
  'Bottle check': 'Verification de la bouteille',
  'Review your bottle without automatically logging water.':
      'Verifiez votre bouteille sans enregistrer automatiquement de l\'eau.',
  'Start, midpoint, and end checks for a flexible shift.':
      'Verifications au debut, au milieu et a la fin d\'un quart flexible.',
  'Start check': 'Verification de debut',
  'Review the plan at the beginning of the shift.':
      'Verifiez le plan au debut du quart.',
  'Midpoint check': 'Verification a mi-parcours',
  'Review progress once the midpoint is reached.':
      'Verifiez la progression une fois la mi-parcours atteint.',
  'End-of-shift review': 'Verification de fin de quart',
  'Finish with a calm review of the completed shift.':
      'Terminez par une verification calme du quart accompli.',
  'A preparation check that happens before travel.':
      'Une verification de preparation effectuee avant le trajet.',
  'Prepare before you go. Do not read, tap, or log while driving.':
      'Preparez-vous avant de partir. Ne lisez pas, ne touchez pas et n\'enregistrez rien en conduisant.',
  'Cup or bottle prepared': 'Tasse ou bouteille preparee',
  'Confirm preparation before the travel period begins.':
      'Confirmez la preparation avant le debut du trajet.',
  'A calm evening review of today’s applied goal.':
      'Une verification calme en soiree de l\'objectif applique aujourd\'hui.',
  'Review without pressure. Do not rapidly catch up late at night.':
      'Verifiez sans pression. Ne rattrapez pas rapidement votre retard tard le soir.',
  'Review today': 'Verifier aujourd\'hui',
  'Review current progress and the applied daily goal.':
      'Verifiez la progression actuelle et l\'objectif quotidien applique.',
  'Finish review': 'Terminer la verification',
  'Confirm the review without adding a hydration log.':
      'Confirmez la verification sans ajouter de journal d\'hydratation.',
  'Build a private lunch-break bottle-check habit.':
      'Developpez une habitude privee de verification de la bouteille a la pause dejeuner.',
  'Check the bottle.': 'Verifiez la bouteille.',
  'Refill if useful.': 'Remplissez-la si cela est utile.',
  'Confirm the check.': 'Confirmez la verification.',
  'One explicit local bottle-check confirmation.':
      'Une confirmation locale explicite de verification de la bouteille.',
  'The check never logs water automatically.':
      'La verification n\'enregistre jamais d\'eau automatiquement.',
  'Pair one study break with a comfortable hydration review.':
      'Associez une pause d\'etude a une verification confortable de l\'hydratation.',
  'Take a study break.': 'Faites une pause d\'etude.',
  'Review hydration.': 'Verifiez l\'hydratation.',
  'One explicit local study-break confirmation.':
      'Une confirmation locale explicite de pause d\'etude.',
  'No school, assignment, or drink amount is inferred.':
      'Aucune information sur l\'ecole, les devoirs ou la quantite bue n\'est deduite.',
  'Review hydration after a daytime routine without pressure.':
      'Verifiez l\'hydratation apres une routine de jour sans pression.',
  'Pause after the routine.': 'Faites une pause apres la routine.',
  'Review the day.': 'Passez la journee en revue.',
  'One explicit local after-routine confirmation.':
      'Une confirmation locale explicite apres la routine.',
  'The check never changes the daily goal.':
      'La verification ne modifie jamais l\'objectif quotidien.',
  'Use a packing cue to prepare a reusable bottle.':
      'Utilisez un signal de rangement pour preparer une bouteille reutilisable.',
  'Prepare it if useful.': 'Preparez-la si cela est utile.',
  'Confirm readiness.': 'Confirmez qu\'elle est prete.',
  'One explicit local bottle-ready confirmation.':
      'Une confirmation locale explicite que la bouteille est prete.',
  'No location or school information is collected.':
      'Aucune information de localisation ou sur l\'ecole n\'est recueillie.',
  'Add a hydration review to an optional seated-work break.':
      'Ajoutez une verification d\'hydratation a une pause facultative du travail assis.',
  'Take a break.': 'Faites une pause.',
  'Confirm the reset.': 'Confirmez la remise a zero.',
  'One explicit local reset confirmation.':
      'Une confirmation locale explicite de remise a zero.',
  'No drink is logged automatically.':
      'Aucune boisson n\'est enregistree automatiquement.',
  'Add an optional midpoint check to a defined work period.':
      'Ajoutez une verification facultative a mi-parcours d\'une periode de travail definie.',
  'Reach the midpoint.': 'Atteignez la mi-parcours.',
  'One explicit local work-period confirmation.':
      'Une confirmation locale explicite de la periode de travail.',
  'Hydrion does not infer employment or a schedule.':
      'Hydrion ne deduit ni emploi ni horaire.',
  'Use optional travel as a cue to review hydration.':
      'Utilisez un trajet facultatif comme signal pour verifier l\'hydratation.',
  'Choose departure or arrival.': 'Choisissez le depart ou l\'arrivee.',
  'Confirm the cue.': 'Confirmez le signal.',
  'One explicit local travel-cue confirmation.':
      'Une confirmation locale explicite du signal de trajet.',
  'No trip or location is tracked.':
      'Aucun trajet ni aucune localisation ne sont suivis.',
  'End the day with a pressure-free review of the existing plan.':
      'Terminez la journee par une verification sans pression du plan existant.',
  'Keep or adjust the plan separately.':
      'Conservez ou ajustez le plan separement.',
  'Confirm review.': 'Confirmez la verification.',
  'One explicit local evening review.':
      'Une verification locale explicite en soiree.',
  'The review never changes the goal automatically.':
      'La verification ne modifie jamais l\'objectif automatiquement.',
  'Temperature Roulette': 'Roulette des temperatures',
  'Cool': 'Frais',
  'Room temperature': 'Temperature ambiante',
  'Comfortably warm': 'Agreablement chaud',
  'TODAY': 'AUJOURD\'HUI',
  'Weather guidance is off. Today’s standard schedule is active.':
      'Les conseils meteo sont desactives. Le programme standard du jour est actif.',
  'Seven-day infusion journey': 'Parcours d\'infusion de sept jours',
  'Meal check-in': 'Confirmation du repas',
  'Water-rich food': 'Aliment riche en eau',
  'Today’s real-world cue': 'Signal concret du jour',
  'Check your plant or bottle station':
      'Verifiez votre plante ou l\'emplacement de votre bouteille',
  'Complete the cue, then check it in. Any water you drink is logged normally and never fabricated.':
      'Effectuez le signal, puis confirmez-le. Toute eau bue est enregistree normalement et n\'est jamais inventee.',
  'Complete hydration habits. Build a line. Keep the board moving.':
      'Completez des habitudes d\'hydratation. Formez une ligne. Faites avancer le tableau.',
  'Choose a tile below': 'Choisissez une tuile ci-dessous',
  'Tiles': 'Tuiles',
  'Lines': 'Lignes',
  'Today': 'Aujourd\'hui',
  'Automatic tiles respond to normal hydration logs. Measured-drink tiles add one canonical hydration record. Habit check-ins never add water.':
      'Les tuiles automatiques reagissent aux journaux d\'hydratation normaux. Les tuiles de boisson mesuree ajoutent une seule entree canonique. Les confirmations d\'habitude n\'ajoutent jamais d\'eau.',
  'Rules': 'Regles',
  'The board has 25 tiles with one completed Free Drop in the center. Complete five across a row, column, or diagonal to build a line.':
      'Le tableau comporte 25 tuiles avec une Goutte libre terminee au centre. Completez-en cinq sur une ligne, une colonne ou une diagonale.',
  'Hydration safety': 'Securite de l\'hydratation',
  'Keep intake comfortable. Do not force fluids to finish a tile or line, and stop if you feel unwell.':
      'Gardez une consommation confortable. Ne forcez pas les liquides pour terminer une tuile ou une ligne et arretez-vous si vous vous sentez mal.',
  'Live board': 'Tableau en direct',
  'Part of a completed Bingo line.':
      'Fait partie d\'une ligne de Bingo terminee.',
  'Double tap for details.': 'Touchez deux fois pour les details.',
  'What to do': 'Action a effectuer',
  'Why it counts': 'Pourquoi cela compte',
  'Home hydration': 'Hydratation de l\'accueil',
  'Adds hydration': 'Ajoute de l\'hydratation',
  'Time window': 'Periode',
  'Current progress': 'Progression actuelle',
  'Set up challenge amount': 'Configurer la quantite du defi',
  'Complete check-in': 'Terminer la confirmation',
  'Free · completed': 'Libre · terminee',
  'In progress': 'En cours',
  'Needs setup': 'Configuration requise',
  'Missed today': 'Manquee aujourd\'hui',
  'Today’s standard temperature plan is in use.':
      'Le plan de temperature standard du jour est utilise.',
  'Review a Bingo tile, follow its exact amount or check-in rule, and complete it once.':
      'Verifiez une tuile de Bingo, suivez sa regle exacte de quantite ou de confirmation et terminez-la une fois.',
  'Complete today’s activity, then mark it complete. Log measured water separately.':
      'Effectuez l\'activite du jour, puis marquez-la comme terminee. Enregistrez l\'eau mesuree separement.',
  'Required before joining': 'Requis avant de rejoindre',
  'Use saved container': 'Utiliser le contenant enregistre',
  'Enabled': 'Active',
  'Disabled': 'Desactive',
  'Confirmed — no added sugar': 'Confirme — sans sucre ajoute',
  'Drink amount in oz': 'Quantite bue en oz',
  'Drink amount': 'Quantite bue',
  'No added sugar': 'Sans sucre ajoute',
  'Weather-guided plan': 'Plan guide par la meteo',
  'Meal': 'Repas',
  'Before-lunch cutoff': 'Limite avant le dejeuner',
  'Early target': 'Objectif precoce',
  'Focus session': 'Session de concentration',
  'Daily sessions': 'Sessions quotidiennes',
  'Short break': 'Courte pause',
  'Session reminder': 'Rappel de session',
  'Auto-start next session': 'Demarrage automatique de la prochaine session',
  'Challenge length': 'Duree du defi',
  'Difficulty': 'Difficulte',
  'Bingo reminder': 'Rappel de Bingo',
  'Plant-care cue': 'Signal de soin de la plante',
  'Routine window': 'Periode de routine',
  'Preparation time': 'Heure de preparation',
  'Travel begins': 'Debut du trajet',
  'Evening review time': 'Heure de verification du soir',
  'Seated-work block': 'Bloc de travail assis',
  'Reset frequency': 'Frequence des pauses',
  'Shift start': 'Debut du quart',
  'Expected shift duration': 'Duree prevue du quart',
  'Checkpoint pattern': 'Modele de checkpoints',
  'Optional reminder': 'Rappel facultatif',
  'Enter confirmed to accept this challenge rule.':
      'Saisissez confirmed pour accepter cette regle du defi.',
  'Enter enabled or disabled. The standard plan remains available.':
      'Saisissez enabled ou disabled. Le plan standard reste disponible.',
  'Breakfast, lunch, dinner, or snack.':
      'Petit-dejeuner, dejeuner, diner ou collation.',
  'A reminder appears when a focus session ends.':
      'Un rappel apparait a la fin d\'une session de concentration.',
  'Choose whether the next session starts after the sip.':
      'Choisissez si la prochaine session demarre apres la gorgee.',
  'Choose gentle, balanced, or active.':
      'Choisissez gentle, balanced ou active.',
  'Minutes after midnight. Overnight shifts are supported.':
      'Minutes apres minuit. Les quarts de nuit sont pris en charge.',
  'The shift may cross local midnight.': 'Le quart peut franchir minuit local.',
  'The preparation action is disabled once this travel hour begins.':
      'L\'action de preparation est desactivee lorsque cette heure de trajet commence.',
  'Enable only after this setup is saved.':
      'Activez uniquement apres l\'enregistrement de cette configuration.',
  'Enter confirmed to accept this rule':
      'Saisissez confirmed pour accepter cette regle',
  'Enter enabled or disabled': 'Saisissez enabled ou disabled',
  'Enter gentle, balanced, or active': 'Saisissez gentle, balanced ou active',
  'Enter a whole number': 'Saisissez un nombre entier',
  'Enter about 1.7–67.6 oz': 'Saisissez environ 1,7 a 67,6 oz',
  'Enter 50–2000 ml': 'Saisissez 50 a 2000 ml',
  'Enter an hour from 0–23': 'Saisissez une heure de 0 a 23',
  'Enter 10–60 percent': 'Saisissez 10 a 60 pour cent',
  'Enter 10–90 minutes': 'Saisissez 10 a 90 minutes',
  'Enter 1–8 sessions': 'Saisissez 1 a 8 sessions',
  'Enter 1–30 minutes': 'Saisissez 1 a 30 minutes',
  'Enter 1–14 days': 'Saisissez 1 a 14 jours',
  'Temperature schedule': 'Programme de temperature',
  'days': 'jours',
  'hours': 'heures',
  'On': 'Active',
  'Off': 'Desactive',
  'Confirmed': 'Confirme',
  'Not set': 'Non defini',
  'Step': 'Etape',
  'Set a daily goal': 'Definir un objectif quotidien',
  'Over goal, ease up': 'Objectif depasse, ralentissez',
  'Goal reached': 'Objectif atteint',
  'Daily progress': 'Progression quotidienne',
  'Hydration reminder': 'Rappel d\'hydratation',
  'Local Hydrion profile': 'Profil Hydrion local',
  'Built around your routine': 'Adapte a votre routine',
  'Your photo, avatar, goals, reminders, and challenge state stay local to this device.':
      'Votre photo, avatar, objectifs, rappels et etat des defis restent sur cet appareil.',
  'Local reminders': 'Rappels locaux',
  'Allow notifications to receive Hydrion reminders. Android settings may affect delivery.':
      'Autorisez les notifications pour recevoir les rappels Hydrion. Les parametres Android peuvent affecter leur livraison.',
  'Active challenges': 'Defis actifs',
  'Other challenges': 'Autres defis',
  'Challenge history': 'Historique des defis',
  'Challenge dock': 'Panneau des defis',
  'Last 7 days': '7 derniers jours',
  'Your active challenges are listed once below with their own progress and actions.':
      'Vos defis actifs sont listes une fois ci-dessous avec leur progression et leurs actions.',
  'Pick a local challenge that adds texture to the routine without turning hydration into pressure.':
      'Choisissez un defi local qui enrichit la routine sans transformer l\'hydratation en pression.',
  'Build a line with everyday hydration habits.':
      'Formez une ligne avec des habitudes d\'hydratation quotidiennes.',
  'Board active': 'Tableau actif',
  'Open board': 'Ouvrir le tableau',
  'Open the board preview': 'Ouvrir l\'apercu du tableau',
  'Challenge drink': 'Boisson du defi',
  'Quick log': 'Journal rapide',
  'Wearable log': 'Journal de l\'appareil portable',
  'Voice log': 'Journal vocal',
  'Hydration entry': 'Entree d\'hydratation',
  'Gentle': 'Doux',
  'Balanced': 'Equilibre',
  'Breakfast': 'Petit-dejeuner',
  'Lunch': 'Dejeuner',
  'Dinner': 'Diner',
  'Snack': 'Collation',
  'Midpoint': 'Mi-parcours',
  'Two-checkpoints': 'Deux checkpoints',
  'Water your plant or check your bottle station':
      'Arrosez votre plante ou verifiez l\'emplacement de votre bouteille',
};

const _challengeSpanishText = <String, String>{
  'Complete setup': 'Completar configuracion',
  'Join challenge': 'Unirse al reto',
  'Pause or leave one challenge first': 'Primero pausa o abandona un reto',
  'You already have two active challenges. Pause or leave one before starting another.':
      'Ya tienes dos retos activos. Pausa o abandona uno antes de iniciar otro.',
  'Continue': 'Continuar',
  'Set up challenge': 'Configurar reto',
  'Challenge paused': 'Reto en pausa',
  'Your progress and hydration history are safe. This challenge is not evaluating new hydration while paused.':
      'Tu progreso y tu historial de hidratacion se conservan. Este reto no evalua nueva hidratacion mientras esta en pausa.',
  'Pause or leave an active challenge before resuming this one.':
      'Pausa o abandona un reto activo antes de reanudar este.',
  'Resume challenge': 'Reanudar reto',
  'Leave challenge': 'Abandonar reto',
  'Challenge complete': 'Reto completado',
  'Measured hydration contribution': 'Contribucion de hidratacion medida',
  'Repeat challenge': 'Repetir reto',
  'Explore another challenge': 'Explorar otro reto',
  'Close': 'Cerrar',
  "Today's instruction": 'Instruccion de hoy',
  "Today's parameters": 'Parametros de hoy',
  "Today's hydration toward your current daily goal":
      'Hidratacion de hoy respecto a tu objetivo diario actual',
  'Challenge-qualified hydration': 'Hidratacion valida para el reto',
  'Challenge progress': 'Progreso del reto',
  'History': 'Historial',
  'Challenge settings': 'Configuracion del reto',
  'Small preferences can apply now or tomorrow. Schedule changes begin with the next activity, while your hydration history stays intact.':
      'Las preferencias pequenas pueden aplicarse ahora o manana. Los cambios de horario empiezan con la siguiente actividad y tu historial de hidratacion permanece intacto.',
  'How it works': 'Como funciona',
  'Edit challenge settings': 'Editar configuracion del reto',
  'Pause': 'Pausar',
  'Recent activity': 'Actividad reciente',
  'See all activity': 'Ver toda la actividad',
  'Replay board guide': 'Repetir la guia del tablero',
  'Pause or leave this challenge from the options menu above. Your hydration records remain intact.':
      'Pausa o abandona este reto desde el menu superior. Tus registros de hidratacion permanecen intactos.',
  'Bottle Bingo activity': 'Actividad de Bottle Bingo',
  'Choose a smaller sip amount or fewer sessions so the plan does not exceed your normal goal.':
      'Elige una cantidad menor o menos sesiones para que el plan no supere tu objetivo normal.',
  'Complete this focus session before confirming your sip.':
      'Completa esta sesion de concentracion antes de confirmar el sorbo.',
  'That sip was already recorded or could not be saved. Check your history before trying again.':
      'Ese sorbo ya se registro o no pudo guardarse. Revisa tu historial antes de intentarlo de nuevo.',
  'Log water normally; qualifying records update this challenge automatically.':
      'Registra el agua normalmente; los registros validos actualizan este reto automaticamente.',
  'Complete the focus session first, or check whether this drink was already recorded.':
      'Primero completa la sesion de concentracion o comprueba si esta bebida ya se registro.',
  'Add drink details': 'Agregar detalles de la bebida',
  'The measured drink counts once. Confirm only details that apply so another active challenge can recognize it.':
      'La bebida medida cuenta una vez. Confirma solo los detalles aplicables para que otro reto activo pueda reconocerla.',
  'Cancel': 'Cancelar',
  'Log measured drink': 'Registrar bebida medida',
  'Challenge complete. Your steady effort counted.':
      'Reto completado. Tu esfuerzo constante conto.',
  'Review qualifying rule': 'Revisar regla de validez',
  'Session notifications': 'Notificaciones de sesion',
  'Applies immediately': 'Se aplica inmediatamente',
  'Future serving amount': 'Cantidad de porciones futuras',
  'Applies next local day. Today’s progress stays the same.':
      'Se aplica el proximo dia local. El progreso de hoy no cambia.',
  'Restart challenge attempt': 'Reiniciar intento del reto',
  'Keeps hydration history and starts challenge progress again.':
      'Conserva el historial de hidratacion y reinicia el progreso del reto.',
  'This change starts tomorrow. Today’s progress will stay the same.':
      'Este cambio empieza manana. El progreso de hoy no cambiara.',
  'Save for tomorrow': 'Guardar para manana',
  'Restart this challenge?': 'Reiniciar este reto?',
  'Restarting creates a new challenge attempt. Your hydration history will remain, but this challenge’s progress will begin again.':
      'Reiniciar crea un nuevo intento. Tu historial de hidratacion permanecera, pero el progreso de este reto comenzara de nuevo.',
  'Keep current attempt': 'Conservar intento actual',
  'Restart': 'Reiniciar',
  'A new challenge attempt has started.': 'Ha comenzado un nuevo intento.',
  'That change could not be saved.': 'No se pudo guardar ese cambio.',
  'Change applied.': 'Cambio aplicado.',
  'The challenge could not be restarted.': 'No se pudo reiniciar el reto.',
  'This setting cannot be changed while the challenge is active.':
      'Este ajuste no se puede cambiar mientras el reto esta activo.',
  'Leave this challenge?': 'Abandonar este reto?',
  'Your hydration history stays intact. Challenge setup and unfinished task progress will be removed.':
      'Tu historial de hidratacion permanece intacto. Se eliminaran la configuracion y el progreso de tareas sin terminar.',
  'Keep challenge': 'Conservar reto',
  'Pause this challenge?': 'Pausar este reto?',
  'Progress and hydration history will stay. New hydration will not qualify until you resume.':
      'El progreso y el historial de hidratacion se conservaran. La nueva hidratacion no contara hasta que reanudes.',
  'Keep active': 'Mantener activo',
  'Leave this paused challenge?': 'Abandonar este reto en pausa?',
  'Hydration history stays. This attempt will remain in challenge history.':
      'El historial de hidratacion se conserva. Este intento permanecera en el historial del reto.',
  'Keep paused': 'Mantener en pausa',
  'Leave': 'Abandonar',
  'You completed the infusion themes in this attempt.':
      'Completaste los temas de infusion de este intento.',
  'You completed the water-rich food task.':
      'Completaste la tarea de alimentos ricos en agua.',
  'You completed this Bottle Bingo board.':
      'Completaste este tablero de Bottle Bingo.',
  'You completed this challenge attempt.': 'Completaste este intento del reto.',
  'Current activity': 'Actividad actual',
  'Start activity': 'Iniciar actividad',
  'Resume': 'Reanudar',
  'Open normal drink logging': 'Abrir el registro normal de bebidas',
  'Opening drink logging does not complete this activity or add water.':
      'Abrir el registro de bebidas no completa esta actividad ni agrega agua.',
  'Completed': 'Completado',
  'Available': 'Disponible',
  'Waiting': 'En espera',
  'Ready': 'Listo',
  'Packed': 'Guardado',
  'Needs attention': 'Necesita atencion',
  'Bottle checked': 'Botella revisada',
  'Refilled': 'Rellenada',
  'Today’s challenge activity is complete.':
      'La actividad del reto de hoy esta completada.',
  'Active': 'Activa',
  'Paused': 'En pausa',
  'Focus session complete': 'Sesion de concentracion completada',
  'Focus session complete. Take your planned sip when you are ready.':
      'Sesion de concentracion completada. Toma el sorbo previsto cuando estes listo.',
  'Sip ready': 'Sorbo listo',
  'Start next focus session': 'Iniciar siguiente sesion',
  'Restart session': 'Reiniciar sesion',
  'End early': 'Terminar antes',
  'Stop today’s plan': 'Detener el plan de hoy',
  'Focus session complete. No water has been added. Confirm Took a sip or log a measured drink when you actually drink.':
      'Sesion de concentracion completada. No se agrego agua. Confirma un sorbo o registra una bebida medida cuando realmente bebas.',
  'A flexible lunch-window bottle check.':
      'Una revision flexible de la botella durante el almuerzo.',
  'Check your bottle': 'Revisa tu botella',
  'Confirm that you checked it. Refill only when that is useful.':
      'Confirma que la revisaste. Rellenala solo cuando sea util.',
  'A private study session with deliberate checkpoints.':
      'Una sesion de estudio privada con puntos de control intencionales.',
  'Hydration check': 'Revision de hidratacion',
  'Review your hydration when the checkpoint is available.':
      'Revisa tu hidratacion cuando el punto este disponible.',
  'Finish the session': 'Finalizar la sesion',
  'Deliberately finish after reviewing the session checkpoint.':
      'Finaliza deliberadamente despues de revisar el punto de la sesion.',
  'A neutral afternoon recharge window.':
      'Un periodo neutro de recarga por la tarde.',
  'Review current progress': 'Revisar progreso actual',
  'Look at today’s hydration progress without pressure.':
      'Observa el progreso de hidratacion de hoy sin presion.',
  'Prepare water': 'Preparar agua',
  'Prepare water if it is useful for the rest of the day.':
      'Prepara agua si resulta util para el resto del dia.',
  'Finish recharge routine': 'Finalizar rutina de recarga',
  'Confirm the short routine is complete.':
      'Confirma que la rutina breve esta completada.',
  'A private reusable-bottle preparation cue.':
      'Una senal privada para preparar una botella reutilizable.',
  'Record bottle status': 'Registrar estado de la botella',
  'Choose ready, packed, or needs attention.':
      'Elige listo, guardado o necesita atencion.',
  'A flexible seated-work reset routine.':
      'Una rutina flexible de pausa para trabajo sentado.',
  'Movement or posture reset': 'Pausa de movimiento o postura',
  'Complete one comfortable reset away from the screen.':
      'Completa una pausa comoda lejos de la pantalla.',
  'Bottle check': 'Revision de la botella',
  'Review your bottle without automatically logging water.':
      'Revisa tu botella sin registrar agua automaticamente.',
  'Start, midpoint, and end checks for a flexible shift.':
      'Revisiones al inicio, a la mitad y al final de un turno flexible.',
  'Start check': 'Revision inicial',
  'Review the plan at the beginning of the shift.':
      'Revisa el plan al comienzo del turno.',
  'Midpoint check': 'Revision de mitad',
  'Review progress once the midpoint is reached.':
      'Revisa el progreso al llegar a la mitad.',
  'End-of-shift review': 'Revision de fin de turno',
  'Finish with a calm review of the completed shift.':
      'Finaliza con una revision tranquila del turno completado.',
  'A preparation check that happens before travel.':
      'Una revision de preparacion antes del viaje.',
  'Prepare before you go. Do not read, tap, or log while driving.':
      'Preparate antes de salir. No leas, pulses ni registres mientras conduces.',
  'Cup or bottle prepared': 'Taza o botella preparada',
  'Confirm preparation before the travel period begins.':
      'Confirma la preparacion antes de que comience el viaje.',
  'A calm evening review of today’s applied goal.':
      'Una revision nocturna tranquila del objetivo aplicado hoy.',
  'Review without pressure. Do not rapidly catch up late at night.':
      'Revisa sin presion. No intentes compensar rapidamente a ultima hora.',
  'Review today': 'Revisar hoy',
  'Review current progress and the applied daily goal.':
      'Revisa el progreso actual y el objetivo diario aplicado.',
  'Finish review': 'Finalizar revision',
  'Confirm the review without adding a hydration log.':
      'Confirma la revision sin agregar un registro de hidratacion.',
  'Build a private lunch-break bottle-check habit.':
      'Crea un habito privado de revisar la botella durante el almuerzo.',
  'Check the bottle.': 'Revisa la botella.',
  'Refill if useful.': 'Rellenala si resulta util.',
  'Confirm the check.': 'Confirma la revision.',
  'One explicit local bottle-check confirmation.':
      'Una confirmacion local explicita de revision de la botella.',
  'The check never logs water automatically.':
      'La revision nunca registra agua automaticamente.',
  'Pair one study break with a comfortable hydration review.':
      'Combina una pausa de estudio con una revision comoda de la hidratacion.',
  'Take a study break.': 'Haz una pausa de estudio.',
  'Review hydration.': 'Revisa la hidratacion.',
  'One explicit local study-break confirmation.':
      'Una confirmacion local explicita de la pausa de estudio.',
  'No school, assignment, or drink amount is inferred.':
      'No se infiere informacion escolar, de tareas ni cantidades de bebida.',
  'Review hydration after a daytime routine without pressure.':
      'Revisa la hidratacion despues de una rutina diurna sin presion.',
  'Pause after the routine.': 'Haz una pausa despues de la rutina.',
  'Review the day.': 'Revisa el dia.',
  'One explicit local after-routine confirmation.':
      'Una confirmacion local explicita despues de la rutina.',
  'The check never changes the daily goal.':
      'La revision nunca cambia el objetivo diario.',
  'Use a packing cue to prepare a reusable bottle.':
      'Usa una senal de preparacion para alistar una botella reutilizable.',
  'Prepare it if useful.': 'Preparala si resulta util.',
  'Confirm readiness.': 'Confirma que esta lista.',
  'One explicit local bottle-ready confirmation.':
      'Una confirmacion local explicita de que la botella esta lista.',
  'No location or school information is collected.':
      'No se recopila informacion de ubicacion ni escolar.',
  'Add a hydration review to an optional seated-work break.':
      'Agrega una revision de hidratacion a una pausa opcional del trabajo sentado.',
  'Take a break.': 'Haz una pausa.',
  'Confirm the reset.': 'Confirma la pausa.',
  'One explicit local reset confirmation.':
      'Una confirmacion local explicita de la pausa.',
  'No drink is logged automatically.':
      'No se registra ninguna bebida automaticamente.',
  'Add an optional midpoint check to a defined work period.':
      'Agrega una revision opcional a mitad de un periodo de trabajo definido.',
  'Reach the midpoint.': 'Llega a la mitad.',
  'One explicit local work-period confirmation.':
      'Una confirmacion local explicita del periodo de trabajo.',
  'Hydrion does not infer employment or a schedule.':
      'Hydrion no infiere empleo ni horarios.',
  'Use optional travel as a cue to review hydration.':
      'Usa un viaje opcional como senal para revisar la hidratacion.',
  'Choose departure or arrival.': 'Elige salida o llegada.',
  'Confirm the cue.': 'Confirma la senal.',
  'One explicit local travel-cue confirmation.':
      'Una confirmacion local explicita de la senal de viaje.',
  'No trip or location is tracked.': 'No se rastrea ningun viaje ni ubicacion.',
  'End the day with a pressure-free review of the existing plan.':
      'Termina el dia con una revision sin presion del plan existente.',
  'Keep or adjust the plan separately.':
      'Conserva o ajusta el plan por separado.',
  'Confirm review.': 'Confirma la revision.',
  'One explicit local evening review.':
      'Una revision local explicita por la noche.',
  'The review never changes the goal automatically.':
      'La revision nunca cambia el objetivo automaticamente.',
  'Temperature Roulette': 'Ruleta de temperatura',
  'Cool': 'Fresca',
  'Room temperature': 'Temperatura ambiente',
  'Comfortably warm': 'Agradablemente tibia',
  'TODAY': 'HOY',
  'Weather guidance is off. Today’s standard schedule is active.':
      'La orientacion meteorologica esta desactivada. El horario estandar de hoy esta activo.',
  'Seven-day infusion journey': 'Recorrido de infusion de siete dias',
  'Meal check-in': 'Confirmacion de comida',
  'Water-rich food': 'Alimento rico en agua',
  'Today’s real-world cue': 'Senal real de hoy',
  'Check your plant or bottle station':
      'Revisa tu planta o el lugar de la botella',
  'Complete the cue, then check it in. Any water you drink is logged normally and never fabricated.':
      'Completa la senal y luego confirmala. El agua que bebas se registra normalmente y nunca se inventa.',
  'Complete hydration habits. Build a line. Keep the board moving.':
      'Completa habitos de hidratacion. Forma una linea. Manten el tablero activo.',
  'Choose a tile below': 'Elige una casilla abajo',
  'Tiles': 'Casillas',
  'Lines': 'Lineas',
  'Today': 'Hoy',
  'Automatic tiles respond to normal hydration logs. Measured-drink tiles add one canonical hydration record. Habit check-ins never add water.':
      'Las casillas automaticas responden a registros normales. Las de bebida medida agregan un solo registro canonico. Las confirmaciones de habitos nunca agregan agua.',
  'Rules': 'Reglas',
  'The board has 25 tiles with one completed Free Drop in the center. Complete five across a row, column, or diagonal to build a line.':
      'El tablero tiene 25 casillas con una Gota libre completada en el centro. Completa cinco en fila, columna o diagonal para formar una linea.',
  'Hydration safety': 'Seguridad de hidratacion',
  'Keep intake comfortable. Do not force fluids to finish a tile or line, and stop if you feel unwell.':
      'Manten una ingesta comoda. No fuerces liquidos para terminar una casilla o linea y detente si te sientes mal.',
  'Live board': 'Tablero en vivo',
  'Part of a completed Bingo line.':
      'Forma parte de una linea de Bingo completada.',
  'Double tap for details.': 'Toca dos veces para ver detalles.',
  'What to do': 'Que hacer',
  'Why it counts': 'Por que cuenta',
  'Home hydration': 'Hidratacion de Inicio',
  'Adds hydration': 'Agrega hidratacion',
  'Time window': 'Periodo',
  'Current progress': 'Progreso actual',
  'Set up challenge amount': 'Configurar cantidad del reto',
  'Complete check-in': 'Completar confirmacion',
  'Free · completed': 'Libre · completada',
  'In progress': 'En progreso',
  'Needs setup': 'Necesita configuracion',
  'Missed today': 'Perdida hoy',
  'Today’s standard temperature plan is in use.':
      'Se esta usando el plan de temperatura estandar de hoy.',
  'Review a Bingo tile, follow its exact amount or check-in rule, and complete it once.':
      'Revisa una casilla de Bingo, sigue su regla exacta de cantidad o confirmacion y completala una vez.',
  'Complete today’s activity, then mark it complete. Log measured water separately.':
      'Completa la actividad de hoy y marcala como completada. Registra el agua medida por separado.',
  'Required before joining': 'Obligatorio antes de unirse',
  'Use saved container': 'Usar recipiente guardado',
  'Enabled': 'Activado',
  'Disabled': 'Desactivado',
  'Confirmed — no added sugar': 'Confirmado — sin azucar agregada',
  'Drink amount in oz': 'Cantidad de bebida en oz',
  'Drink amount': 'Cantidad de bebida',
  'No added sugar': 'Sin azucar agregada',
  'Weather-guided plan': 'Plan guiado por el clima',
  'Meal': 'Comida',
  'Before-lunch cutoff': 'Limite antes del almuerzo',
  'Early target': 'Objetivo temprano',
  'Focus session': 'Sesion de concentracion',
  'Daily sessions': 'Sesiones diarias',
  'Short break': 'Pausa breve',
  'Session reminder': 'Recordatorio de sesion',
  'Auto-start next session': 'Inicio automatico de la siguiente sesion',
  'Challenge length': 'Duracion del reto',
  'Difficulty': 'Dificultad',
  'Bingo reminder': 'Recordatorio de Bingo',
  'Plant-care cue': 'Senal de cuidado de plantas',
  'Routine window': 'Periodo de rutina',
  'Preparation time': 'Hora de preparacion',
  'Travel begins': 'Inicio del viaje',
  'Evening review time': 'Hora de revision nocturna',
  'Seated-work block': 'Bloque de trabajo sentado',
  'Reset frequency': 'Frecuencia de pausas',
  'Shift start': 'Inicio del turno',
  'Expected shift duration': 'Duracion prevista del turno',
  'Checkpoint pattern': 'Patron de puntos de control',
  'Optional reminder': 'Recordatorio opcional',
  'Enter confirmed to accept this challenge rule.':
      'Escribe confirmed para aceptar esta regla del reto.',
  'Enter enabled or disabled. The standard plan remains available.':
      'Escribe enabled o disabled. El plan estandar sigue disponible.',
  'Breakfast, lunch, dinner, or snack.': 'Desayuno, almuerzo, cena o merienda.',
  'A reminder appears when a focus session ends.':
      'Aparece un recordatorio al terminar una sesion de concentracion.',
  'Choose whether the next session starts after the sip.':
      'Elige si la siguiente sesion comienza despues del sorbo.',
  'Choose gentle, balanced, or active.': 'Elige gentle, balanced o active.',
  'Minutes after midnight. Overnight shifts are supported.':
      'Minutos despues de medianoche. Se admiten turnos nocturnos.',
  'The shift may cross local midnight.':
      'El turno puede cruzar la medianoche local.',
  'The preparation action is disabled once this travel hour begins.':
      'La accion de preparacion se desactiva cuando comienza esta hora de viaje.',
  'Enable only after this setup is saved.':
      'Activa solo despues de guardar esta configuracion.',
  'Enter confirmed to accept this rule':
      'Escribe confirmed para aceptar esta regla',
  'Enter enabled or disabled': 'Escribe enabled o disabled',
  'Enter gentle, balanced, or active': 'Escribe gentle, balanced o active',
  'Enter a whole number': 'Escribe un numero entero',
  'Enter about 1.7–67.6 oz': 'Escribe aproximadamente 1,7–67,6 oz',
  'Enter 50–2000 ml': 'Escribe 50–2000 ml',
  'Enter an hour from 0–23': 'Escribe una hora de 0 a 23',
  'Enter 10–60 percent': 'Escribe entre 10 y 60 por ciento',
  'Enter 10–90 minutes': 'Escribe entre 10 y 90 minutos',
  'Enter 1–8 sessions': 'Escribe entre 1 y 8 sesiones',
  'Enter 1–30 minutes': 'Escribe entre 1 y 30 minutos',
  'Enter 1–14 days': 'Escribe entre 1 y 14 dias',
  'Temperature schedule': 'Programa de temperatura',
  'days': 'dias',
  'hours': 'horas',
  'On': 'Activado',
  'Off': 'Desactivado',
  'Confirmed': 'Confirmado',
  'Not set': 'Sin definir',
  'Step': 'Paso',
  'Set a daily goal': 'Establecer un objetivo diario',
  'Over goal, ease up': 'Objetivo superado, reduce el ritmo',
  'Goal reached': 'Objetivo alcanzado',
  'Daily progress': 'Progreso diario',
  'Hydration reminder': 'Recordatorio de hidratacion',
  'Local Hydrion profile': 'Perfil local de Hydrion',
  'Built around your routine': 'Adaptado a tu rutina',
  'Your photo, avatar, goals, reminders, and challenge state stay local to this device.':
      'Tu foto, avatar, objetivos, recordatorios y estado de retos permanecen en este dispositivo.',
  'Local reminders': 'Recordatorios locales',
  'Allow notifications to receive Hydrion reminders. Android settings may affect delivery.':
      'Permite las notificaciones para recibir recordatorios de Hydrion. Los ajustes de Android pueden afectar la entrega.',
  'Active challenges': 'Retos activos',
  'Other challenges': 'Otros retos',
  'Challenge history': 'Historial de retos',
  'Challenge dock': 'Panel de retos',
  'Last 7 days': 'Ultimos 7 dias',
  'Your active challenges are listed once below with their own progress and actions.':
      'Tus retos activos aparecen una vez abajo con su progreso y acciones.',
  'Pick a local challenge that adds texture to the routine without turning hydration into pressure.':
      'Elige un reto local que aporte variedad sin convertir la hidratacion en presion.',
  'Build a line with everyday hydration habits.':
      'Forma una linea con habitos cotidianos de hidratacion.',
  'Board active': 'Tablero activo',
  'Open board': 'Abrir tablero',
  'Open the board preview': 'Abrir vista previa del tablero',
  'Challenge drink': 'Bebida del reto',
  'Quick log': 'Registro rapido',
  'Wearable log': 'Registro de dispositivo',
  'Voice log': 'Registro de voz',
  'Hydration entry': 'Entrada de hidratacion',
  'Gentle': 'Suave',
  'Balanced': 'Equilibrado',
  'Breakfast': 'Desayuno',
  'Lunch': 'Almuerzo',
  'Dinner': 'Cena',
  'Snack': 'Merienda',
  'Midpoint': 'Mitad',
  'Two-checkpoints': 'Dos puntos de control',
  'Water your plant or check your bottle station':
      'Riega tu planta o revisa el lugar de tu botella',
};
