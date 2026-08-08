import '../domain/hydration_contracts.dart';
import 'app_localizations.dart';

extension HydrionCoachLocalizations on AppLocalizations {
  String localCoachFallback({
    required HydrationContext context,
    required String userQuery,
  }) {
    final query = userQuery.trim();
    final events = context.eventCount;
    final consumed = context.dailySummary.consumedMl;
    final lifetime = context.lifetimeMl;
    final french = localeName.toLowerCase().startsWith('fr');
    final spanish = localeName.toLowerCase().startsWith('es');

    if (french) {
      final contextCopy = events == 0
          ? 'Aucune consommation d\'eau enregistree pour le moment.'
          : 'Aujourd\'hui : $consumed ml. Total suivi : $lifetime ml dans $events ${events == 1 ? 'entree enregistree' : 'entrees enregistrees'}.';
      final queryCopy = query.isEmpty ? '' : ' Votre question : $query';
      return 'Hydrion utilise les conseils sur l\'appareil. $contextCopy$queryCopy';
    }
    if (spanish) {
      final contextCopy = events == 0
          ? 'Todavia no hay registros de hidratacion guardados.'
          : 'Hoy: $consumed ml. Total registrado: $lifetime ml en $events ${events == 1 ? 'registro guardado' : 'registros guardados'}.';
      final queryCopy = query.isEmpty ? '' : ' Tu pregunta: $query';
      return 'Hydrion usa orientacion en el dispositivo. $contextCopy$queryCopy';
    }
    final contextCopy = events == 0
        ? 'No saved hydration logs yet.'
        : 'Today: $consumed ml. Lifetime tracked: $lifetime ml across $events ${events == 1 ? 'saved log' : 'saved logs'}.';
    final queryCopy = query.isEmpty ? '' : ' You asked: $query';
    return 'Hydrion is using on-device guidance. $contextCopy$queryCopy';
  }
}
