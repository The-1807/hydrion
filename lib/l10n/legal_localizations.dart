import '../domain/legal_document_registry.dart';
import 'app_localizations.dart';

class LocalizedLegalDocumentCopy {
  const LocalizedLegalDocumentCopy({
    required this.title,
    required this.description,
    required this.accessibilityLabel,
  });

  final String title;
  final String description;
  final String accessibilityLabel;
}

extension HydrionLegalLocalizations on AppLocalizations {
  bool get _isFrench => localeName.toLowerCase().startsWith('fr');
  bool get _isSpanish => localeName.toLowerCase().startsWith('es');

  String legalText(String english) {
    if (_isFrench) return _french[english] ?? english;
    if (_isSpanish) return _spanish[english] ?? english;
    return english;
  }

  String legalVersion(String version) =>
      legalText('Version {version}').replaceAll('{version}', version);

  String get legalEnglishOnlyNotice => legalText(
      'This legal document is currently available in English. The English document is authoritative.');
  String get legalContinueInEnglish => legalText('Continue in English');
  String get legalReturn => legalText('Return');

  String legalDocumentOpened(String title) => _isFrench
      ? '$title ouvert'
      : _isSpanish
          ? '$title abierto'
          : '$title opened';

  String legalDocumentTooltip(LocalizedLegalDocumentCopy copy, String version,
          {required bool opened}) =>
      opened
          ? _isFrench
              ? '${copy.accessibilityLabel}. Ouvert pour la version $version.'
              : _isSpanish
                  ? '${copy.accessibilityLabel}. Abierto para la version $version.'
                  : '${copy.accessibilityLabel}. Opened for version $version.'
          : copy.accessibilityLabel;

  LocalizedLegalDocumentCopy legalDocumentCopy(HydrionLegalDocument document) {
    final values = _documentCopy[document.id];
    if (values == null) {
      return LocalizedLegalDocumentCopy(
        title: document.title,
        description: document.description,
        accessibilityLabel: document.accessibilityLabel,
      );
    }
    final index = _isFrench ? 1 : (_isSpanish ? 2 : 0);
    return LocalizedLegalDocumentCopy(
      title: values[index][0],
      description: values[index][1],
      accessibilityLabel: values[index][2],
    );
  }
}

const _french = <String, String>{
  'One quick review': 'Une verification rapide',
  'Hydrion now stores versioned Terms acceptance and a separate Health and Safety acknowledgement locally. Your hydration logs and profile data are not reset.':
      'Hydrion enregistre maintenant localement votre acceptation versionnee des Conditions ainsi qu\'un accuse distinct concernant la sante et la securite. Vos journaux d\'hydratation et donnees de profil ne sont pas reinitialises.',
  'Legal review': 'Verification juridique',
  'Hydrion is a general wellness tracker. The documents remain available below; checking the boxes records your acceptance and acknowledgement.':
      'Hydrion est un outil de suivi du bien-etre general. Les documents restent accessibles ci-dessous; cocher les cases enregistre votre acceptation et votre accuse.',
  'Check this box to accept the current Terms.':
      'Cochez cette case pour accepter les Conditions actuelles.',
  'Check this box to acknowledge the health disclaimer.':
      'Cochez cette case pour confirmer l\'avis de non-responsabilite relatif a la sante.',
  'Current legal review recorded':
      'Verification juridique actuelle enregistree',
  'Legal review needed': 'Verification juridique requise',
  'A local-first hydration companion for water logging, goals, reminders, and gentle challenges.':
      'Un compagnon d\'hydratation local pour les journaux, objectifs, rappels et defis en douceur.',
  'Credits and licences': 'Credits et licences',
  'Loading animation obtained from LottieFiles and bundled for Hydrion. Source-page creator and licence evidence are recorded in THIRD_PARTY_NOTICES.md before release.':
      'Animation de chargement obtenue sur LottieFiles et incluse avec Hydrion. Le createur de la page source et la preuve de licence sont consignes dans THIRD_PARTY_NOTICES.md avant la publication.',
  'App information': 'Informations sur l\'application',
  'Version': 'Version',
  'Bundle': 'Identifiant',
  'Mode': 'Mode',
  'Local-first MVP': 'MVP local en priorite',
  'Document unavailable': 'Document indisponible',
  'Hydrion could not load this bundled legal document. Please return to About & Legal and try another document.':
      'Hydrion n\'a pas pu charger ce document juridique inclus. Revenez a A propos et juridique, puis essayez un autre document.',
  'Version {version}': 'Version {version}',
  'This legal document is currently available in English. The English document is authoritative.':
      'Ce document juridique est actuellement disponible en anglais. Le document anglais fait foi.',
  'Continue in English': 'Continuer en anglais',
  'Return': 'Retour',
};

const _spanish = <String, String>{
  'One quick review': 'Una revision rapida',
  'Hydrion now stores versioned Terms acceptance and a separate Health and Safety acknowledgement locally. Your hydration logs and profile data are not reset.':
      'Hydrion ahora guarda localmente la aceptacion versionada de los Terminos y una confirmacion separada de Salud y Seguridad. Tus registros de hidratacion y datos del perfil no se restablecen.',
  'Legal review': 'Revision legal',
  'Hydrion is a general wellness tracker. The documents remain available below; checking the boxes records your acceptance and acknowledgement.':
      'Hydrion es un registro de bienestar general. Los documentos siguen disponibles abajo; marcar las casillas registra tu aceptacion y confirmacion.',
  'Check this box to accept the current Terms.':
      'Marca esta casilla para aceptar los Terminos actuales.',
  'Check this box to acknowledge the health disclaimer.':
      'Marca esta casilla para confirmar el aviso de salud.',
  'Current legal review recorded': 'Revision legal actual registrada',
  'Legal review needed': 'Revision legal necesaria',
  'A local-first hydration companion for water logging, goals, reminders, and gentle challenges.':
      'Un asistente de hidratacion local para registros, objetivos, recordatorios y retos moderados.',
  'Credits and licences': 'Creditos y licencias',
  'Loading animation obtained from LottieFiles and bundled for Hydrion. Source-page creator and licence evidence are recorded in THIRD_PARTY_NOTICES.md before release.':
      'Animacion de carga obtenida de LottieFiles e incluida con Hydrion. El creador de la pagina de origen y la prueba de licencia se registran en THIRD_PARTY_NOTICES.md antes del lanzamiento.',
  'App information': 'Informacion de la aplicacion',
  'Version': 'Version',
  'Bundle': 'Paquete',
  'Mode': 'Modo',
  'Local-first MVP': 'MVP local primero',
  'Document unavailable': 'Documento no disponible',
  'Hydrion could not load this bundled legal document. Please return to About & Legal and try another document.':
      'Hydrion no pudo cargar este documento legal incluido. Vuelve a Informacion y legal e intenta abrir otro documento.',
  'Version {version}': 'Version {version}',
  'This legal document is currently available in English. The English document is authoritative.':
      'Este documento legal esta disponible actualmente en ingles. El documento en ingles es el autorizado.',
  'Continue in English': 'Continuar en ingles',
  'Return': 'Volver',
};

const _documentCopy = <String, List<List<String>>>{
  'terms': [
    ['Terms of Use', 'Rules for using Hydrion.', 'Open the Terms of Use'],
    [
      'Conditions d\'utilisation',
      'Regles d\'utilisation de Hydrion.',
      'Ouvrir les Conditions d\'utilisation'
    ],
    [
      'Terminos de uso',
      'Reglas para usar Hydrion.',
      'Abrir los Terminos de uso'
    ],
  ],
  'privacy': [
    ['Privacy Policy', 'How Hydrion handles data.', 'Open the Privacy Policy'],
    [
      'Politique de confidentialite',
      'Comment Hydrion traite les donnees.',
      'Ouvrir la Politique de confidentialite'
    ],
    [
      'Politica de privacidad',
      'Como gestiona Hydrion los datos.',
      'Abrir la Politica de privacidad'
    ],
  ],
  'health': [
    [
      'Health and Safety Disclaimer',
      'Important wellness and safety limits.',
      'Open the Health and Wellness Disclaimer'
    ],
    [
      'Avis de sante et de bien-etre',
      'Limites importantes de bien-etre et de securite.',
      'Ouvrir l\'avis de sante et de bien-etre'
    ],
    [
      'Aviso de salud y bienestar',
      'Limites importantes de bienestar y seguridad.',
      'Abrir el Aviso de salud y bienestar'
    ],
  ],
  'beta': [
    [
      'Alpha and Beta Testing Notice',
      'Terms for prerelease testing.',
      'Open the Alpha and Beta Testing Notice'
    ],
    [
      'Avis sur les tests alpha et beta',
      'Conditions des essais en avant-premiere.',
      'Ouvrir l\'avis sur les tests alpha et beta'
    ],
    [
      'Aviso de pruebas alfa y beta',
      'Condiciones para pruebas preliminares.',
      'Abrir el aviso de pruebas alfa y beta'
    ],
  ],
};
