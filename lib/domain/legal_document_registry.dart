class HydrionLegalDocument {
  final String id;
  final String title;
  final String description;
  final String assetPath;
  final String version;
  final DateTime effectiveDate;
  final DateTime lastUpdated;
  final bool requiresTermsAcceptance;
  final bool requiresHealthAcknowledgement;
  final bool userFacing;
  final bool internalOnly;
  final String routeName;
  final Uri? publicUrl;
  final String accessibilityLabel;

  const HydrionLegalDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
    required this.version,
    required this.effectiveDate,
    required this.lastUpdated,
    required this.requiresTermsAcceptance,
    required this.requiresHealthAcknowledgement,
    required this.userFacing,
    required this.internalOnly,
    required this.routeName,
    required this.publicUrl,
    required this.accessibilityLabel,
  });
}

class HydrionLegalDocumentRegistry {
  static final terms = HydrionLegalDocument(
    id: 'terms',
    title: 'Terms of Use',
    description:
        'Contractual rules for using Hydrion, including local-first limits.',
    assetPath: 'docs/Hydrion_Legal_Pack_Markdown/02_TERMS_OF_USE.md',
    version: '1.0.0',
    effectiveDate: DateTime(2026, 7, 6),
    lastUpdated: DateTime(2026, 7, 6),
    requiresTermsAcceptance: true,
    requiresHealthAcknowledgement: false,
    userFacing: true,
    internalOnly: false,
    routeName: '/legal/terms',
    publicUrl: null,
    accessibilityLabel: 'Read Hydrion Terms of Use',
  );

  static final privacy = HydrionLegalDocument(
    id: 'privacy',
    title: 'Privacy Policy',
    description:
        'How Hydrion handles local data, weather requests, photos, and support.',
    assetPath: 'docs/Hydrion_Legal_Pack_Markdown/01_PRIVACY_POLICY.md',
    version: '1.0.1',
    effectiveDate: DateTime(2026, 7, 6),
    lastUpdated: DateTime(2026, 7, 6),
    requiresTermsAcceptance: false,
    requiresHealthAcknowledgement: false,
    userFacing: true,
    internalOnly: false,
    routeName: '/legal/privacy',
    publicUrl: null,
    accessibilityLabel: 'Read Hydrion Privacy Policy',
  );

  static final health = HydrionLegalDocument(
    id: 'health',
    title: 'Health and Safety Disclaimer',
    description:
        'General wellness limits, hydration safety, and emergency guidance.',
    assetPath:
        'docs/Hydrion_Legal_Pack_Markdown/03_HEALTH_AND_WELLNESS_DISCLAIMER.md',
    version: '1.0.0',
    effectiveDate: DateTime(2026, 7, 6),
    lastUpdated: DateTime(2026, 7, 6),
    requiresTermsAcceptance: false,
    requiresHealthAcknowledgement: true,
    userFacing: true,
    internalOnly: false,
    routeName: '/legal/health',
    publicUrl: null,
    accessibilityLabel: 'Read Hydrion Health and Safety Disclaimer',
  );

  static final beta = HydrionLegalDocument(
    id: 'beta',
    title: 'Alpha and Beta Testing Notice',
    description: 'What to expect from unfinished Hydrion test builds.',
    assetPath:
        'docs/Hydrion_Legal_Pack_Markdown/04_ALPHA_BETA_TESTING_NOTICE.md',
    version: '1.0.0',
    effectiveDate: DateTime(2026, 7, 6),
    lastUpdated: DateTime(2026, 7, 6),
    requiresTermsAcceptance: false,
    requiresHealthAcknowledgement: false,
    userFacing: true,
    internalOnly: false,
    routeName: '/legal/beta',
    publicUrl: null,
    accessibilityLabel: 'Read Hydrion Alpha and Beta Testing Notice',
  );

  static final internalPublishNote = HydrionLegalDocument(
    id: 'internal_publish_note',
    title: 'Read Before Publishing',
    description: 'Internal owner review notes.',
    assetPath: 'docs/Hydrion_Legal_Pack_Markdown/00_READ_BEFORE_PUBLISHING.md',
    version: '1.0.0',
    effectiveDate: DateTime(2026, 7, 6),
    lastUpdated: DateTime(2026, 7, 6),
    requiresTermsAcceptance: false,
    requiresHealthAcknowledgement: false,
    userFacing: false,
    internalOnly: true,
    routeName: '/legal/internal-publish-note',
    publicUrl: null,
    accessibilityLabel: 'Internal Hydrion publishing note',
  );

  static final internalDraftingReferences = HydrionLegalDocument(
    id: 'internal_drafting_references',
    title: 'Internal Drafting References',
    description: 'Internal drafting references.',
    assetPath:
        'docs/Hydrion_Legal_Pack_Markdown/05_INTERNAL_DRAFTING_REFERENCES.md',
    version: '1.0.0',
    effectiveDate: DateTime(2026, 7, 6),
    lastUpdated: DateTime(2026, 7, 6),
    requiresTermsAcceptance: false,
    requiresHealthAcknowledgement: false,
    userFacing: false,
    internalOnly: true,
    routeName: '/legal/internal-drafting-references',
    publicUrl: null,
    accessibilityLabel: 'Internal Hydrion drafting references',
  );

  static final documents = <HydrionLegalDocument>[
    terms,
    privacy,
    health,
    beta,
    internalPublishNote,
    internalDraftingReferences,
  ];

  static Iterable<HydrionLegalDocument> get userFacingDocuments =>
      documents.where((document) => document.userFacing);

  static Iterable<HydrionLegalDocument> get internalDocuments =>
      documents.where((document) => document.internalOnly);

  static HydrionLegalDocument? byId(String id) {
    for (final document in documents) {
      if (document.id == id) {
        return document;
      }
    }
    return null;
  }

  static HydrionLegalDocument? byRoute(String routeName) {
    for (final document in documents) {
      if (document.routeName == routeName) {
        return document;
      }
    }
    return null;
  }
}

class HydrionLegalAcceptancePolicy {
  static String get requiredTermsAcceptanceVersion =>
      HydrionLegalDocumentRegistry.terms.version;

  static String get requiredHealthAcknowledgementVersion =>
      HydrionLegalDocumentRegistry.health.version;

  static String get currentPrivacyNoticeVersion =>
      HydrionLegalDocumentRegistry.privacy.version;

  static bool hasCurrentTermsAcceptance(String? acceptedVersion) {
    return acceptedVersion == requiredTermsAcceptanceVersion;
  }

  static bool hasCurrentHealthAcknowledgement(String? acknowledgedVersion) {
    return acknowledgedVersion == requiredHealthAcknowledgementVersion;
  }

  static bool needsReview({
    required bool onboardingCompleted,
    required String? acceptedTermsVersion,
    required String? acknowledgedHealthDisclaimerVersion,
    String requiredTermsVersion = '',
    String requiredHealthVersion = '',
  }) {
    if (!onboardingCompleted) {
      return false;
    }
    final termsVersion = requiredTermsVersion.isEmpty
        ? requiredTermsAcceptanceVersion
        : requiredTermsVersion;
    final healthVersion = requiredHealthVersion.isEmpty
        ? requiredHealthAcknowledgementVersion
        : requiredHealthVersion;
    return acceptedTermsVersion != termsVersion ||
        acknowledgedHealthDisclaimerVersion != healthVersion;
  }
}
