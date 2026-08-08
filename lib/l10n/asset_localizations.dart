import '../domain/ui_asset_manifest.dart';
import 'app_localizations.dart';

extension HydrionAssetLocalizations on AppLocalizations {
  String sceneDescription(HydrionUiScene scene) {
    final locale = localeName.toLowerCase();
    if (locale.startsWith('fr')) {
      return _sceneFrench[scene.id] ?? scene.description;
    }
    if (locale.startsWith('es')) {
      return _sceneSpanish[scene.id] ?? scene.description;
    }
    return scene.description;
  }
}

const _sceneFrench = <String, String>{
  'app-check': 'Une personne verifie Hydrion apres avoir enregistre de l\'eau.',
  'blue-kit': 'Illustration du suivi de la consommation dans Hydrion.',
  'neutral-bottle': 'Illustration neutre d\'une bouteille d\'eau Hydrion.',
  'neutral-infusion': 'Illustration neutre d\'une bouteille d\'eau infusee.',
  'neutral-temperature':
      'Illustration neutre d\'un distributeur d\'eau chaude et froide.',
  'bottle-break':
      'Une personne fait une pause detendue avec sa bouteille Hydrion.',
  'cooldown': 'Un personnage Hydrion pret apres un entrainement ou une marche.',
  'plan-check': 'Une personne verifie sa progression Hydrion sur un telephone.',
  'portrait': 'Une personne boit de l\'eau avec Hydrion.',
  'community-run': 'Illustration d\'une course communautaire locale.',
  'challenge': 'Illustration d\'un defi Hydrion.',
  'goals': 'Illustration des objectifs Hydrion.',
  'goals-lady': 'Une personne verifie ses objectifs d\'hydratation Hydrion.',
  'men-goals': 'Une personne verifie ses objectifs d\'hydratation Hydrion.',
  'weather': 'Illustration meteo Hydrion.',
  'hot-summer': 'Illustration Hydrion par temps chaud.',
  'runner': 'Un coureur Hydrion pret pour une routine active.',
  'runner-ready': 'Une personne Hydrion prete pour une routine active legere.',
  'sip-break': 'Une gorgee calme avec la bouteille Hydrion.',
  'studio-bottle': 'Une personne Hydrion dans une routine active.',
  'pride-be-proud-flag': 'Illustration d\'un drapeau d\'encouragement Pride.',
  'pride-be-proud': 'Illustration d\'encouragement Pride.',
  'pride-eat-your-water':
      'Illustration Pride sur l\'hydratation et les aliments.',
  'pride-gender': 'Illustration Pride sur l\'identite.',
  'pride-banner': 'Illustration d\'une banniere Pride.',
  'pride-bottle': 'Illustration Pride d\'une bouteille d\'hydratation.',
};

const _sceneSpanish = <String, String>{
  'app-check': 'Una persona revisa Hydrion despues de registrar agua.',
  'blue-kit': 'Ilustracion del seguimiento de consumo en Hydrion.',
  'neutral-bottle': 'Ilustracion neutra de una botella de agua Hydrion.',
  'neutral-infusion': 'Ilustracion neutra de una botella de agua infusionada.',
  'neutral-temperature':
      'Ilustracion neutra de un dispensador de agua fria y caliente.',
  'bottle-break': 'Una persona toma una pausa relajada con su botella Hydrion.',
  'cooldown': 'Un personaje Hydrion listo despues de entrenar o caminar.',
  'plan-check': 'Una persona revisa su progreso Hydrion en un telefono.',
  'portrait': 'Una persona bebe agua con Hydrion.',
  'community-run': 'Ilustracion de una carrera comunitaria local.',
  'challenge': 'Ilustracion de un reto Hydrion.',
  'goals': 'Ilustracion de objetivos Hydrion.',
  'goals-lady': 'Una persona revisa sus objetivos de hidratacion Hydrion.',
  'men-goals': 'Una persona revisa sus objetivos de hidratacion Hydrion.',
  'weather': 'Ilustracion meteorologica de Hydrion.',
  'hot-summer': 'Ilustracion de Hydrion para clima caluroso.',
  'runner': 'Un corredor Hydrion listo para una rutina activa.',
  'runner-ready': 'Una persona Hydrion lista para una rutina activa ligera.',
  'sip-break': 'Un sorbo tranquilo con la botella Hydrion.',
  'studio-bottle': 'Una persona Hydrion en una rutina activa.',
  'pride-be-proud-flag': 'Ilustracion de una bandera de apoyo Pride.',
  'pride-be-proud': 'Ilustracion de apoyo Pride.',
  'pride-eat-your-water': 'Ilustracion Pride sobre hidratacion y alimentos.',
  'pride-gender': 'Ilustracion Pride sobre identidad.',
  'pride-banner': 'Ilustracion de una pancarta Pride.',
  'pride-bottle': 'Ilustracion Pride de una botella de hidratacion.',
};
