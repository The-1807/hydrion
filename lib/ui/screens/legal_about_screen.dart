import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../../domain/community_links.dart';
import '../../domain/legal_document_registry.dart';
import '../../domain/release_metadata.dart';
import '../../repositories/settings_repository.dart';
import '../theme/hydrion_design.dart';

class LegalAboutScreen extends StatelessWidget {
  const LegalAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = HydrionLegalDocumentRegistry.userFacingDocuments.toList();
    final settings = context.watch<UserSettingsRepository>().settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Legal'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            _LegalIntroCard(settings: settings),
            const SizedBox(height: 12),
            for (final document in documents) ...[
              _LegalDocumentTile(document: document),
              const SizedBox(height: 8),
            ],
            _UtilityTile(
              key: const Key('legal-open-source-licenses'),
              icon: Icons.code_outlined,
              title: 'Open Source Licenses',
              description: 'Flutter and package license notices.',
              onTap: () => showLicensePage(
                context: context,
                applicationName: HydrionReleaseMetadata.productName,
                applicationVersion: HydrionReleaseMetadata.flutterVersionName,
                applicationLegalese:
                    'Hydrion uses open-source components under their licenses.',
              ),
            ),
            const SizedBox(height: 8),
            const _AppInfoTile(),
            const SizedBox(height: 8),
            const _SupportTile(),
          ],
        ),
      ),
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  final String documentId;

  const LegalDocumentScreen({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    final document = HydrionLegalDocumentRegistry.byId(documentId);
    final colorScheme = Theme.of(context).colorScheme;

    if (document == null || document.internalOnly) {
      return Scaffold(
        appBar: AppBar(title: const Text('Legal document')),
        body: const _LegalMissingState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: math.min(constraints.maxWidth, 820),
                height: constraints.maxHeight,
                child: FutureBuilder<String>(
                  future: rootBundle.loadString(document.assetPath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          key: Key('legal-document-loading'),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const _LegalMissingState();
                    }
                    final data = _stripFrontMatter(snapshot.data!);
                    return Markdown(
                      key: Key('legal-document-${document.id}'),
                      data: data,
                      selectable: true,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        Theme.of(context),
                      ).copyWith(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.45,
                            ),
                        h1: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                        h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                        a: TextStyle(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _DocumentMetadataBar(document: document),
          ),
        ),
      ),
    );
  }
}

class LegalReviewScreen extends StatefulWidget {
  const LegalReviewScreen({super.key});

  @override
  State<LegalReviewScreen> createState() => _LegalReviewScreenState();
}

class _LegalReviewScreenState extends State<LegalReviewScreen> {
  bool _termsAccepted = false;
  bool _healthAcknowledged = false;

  Future<void> _continue() async {
    if (!_termsAccepted || !_healthAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms and acknowledge the health disclaimer.',
          ),
        ),
      );
      return;
    }
    await context.read<UserSettingsRepository>().recordLegalReview();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Review Hydrion terms'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                HydrionSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One quick review',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hydrion now stores versioned Terms acceptance and a separate Health and Safety acknowledgement locally. Your hydration logs and profile data are not reset.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LegalAcceptancePanel(
                  termsAccepted: _termsAccepted,
                  healthAcknowledged: _healthAcknowledged,
                  onTermsChanged: (value) {
                    setState(() => _termsAccepted = value);
                  },
                  onHealthChanged: (value) {
                    setState(() => _healthAcknowledged = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            key: const Key('legal-review-continue'),
            onPressed: _continue,
            icon: const Icon(Icons.check),
            label: const Text('Continue to Hydrion'),
          ),
        ),
      ),
    );
  }
}

class LegalAcceptancePanel extends StatelessWidget {
  final bool termsAccepted;
  final bool healthAcknowledged;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onHealthChanged;

  const LegalAcceptancePanel({
    super.key,
    required this.termsAccepted,
    required this.healthAcknowledged,
    required this.onTermsChanged,
    required this.onHealthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Legal review',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hydrion is a general wellness tracker. Review the documents below before continuing. The Privacy Policy is a notice, not a contract checkbox.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DocumentChip(document: HydrionLegalDocumentRegistry.terms),
              _DocumentChip(document: HydrionLegalDocumentRegistry.privacy),
              _DocumentChip(document: HydrionLegalDocumentRegistry.health),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: const Key('onboarding-terms-accept'),
            contentPadding: EdgeInsets.zero,
            value: termsAccepted,
            onChanged: (value) => onTermsChanged(value == true),
            title: const Text('I accept the Hydrion Terms of Use.'),
            subtitle: Text(
              'Version ${HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion}',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            key: const Key('onboarding-health-ack'),
            contentPadding: EdgeInsets.zero,
            value: healthAcknowledged,
            onChanged: (value) => onHealthChanged(value == true),
            title: const Text(
              'I acknowledge the Health and Safety Disclaimer.',
            ),
            subtitle: Text(
              'Version ${HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion}',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}

class _LegalIntroCard extends StatelessWidget {
  final UserSettings settings;

  const _LegalIntroCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final legalStatus = settings.hasCurrentLegalReview
        ? 'Current legal review recorded'
        : 'Legal review needed';
    return HydrionSurface(
      gradient: HydrionGradients.ocean,
      radius: HydrionRadii.lg,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydrion',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A local-first hydration companion for water logging, goals, reminders, and gentle challenges.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const _IntroPill(
                  label: 'Version ${HydrionReleaseMetadata.flutterVersionName}',
                ),
                const _IntroPill(
                    label: HydrionReleaseMetadata.releaseDateLabel),
                _IntroPill(label: legalStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocumentTile extends StatelessWidget {
  final HydrionLegalDocument document;

  const _LegalDocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    return _UtilityTile(
      key: Key('legal-document-tile-${document.id}'),
      icon: _iconFor(document.id),
      title: document.title,
      description: document.description,
      onTap: () => Navigator.of(context).pushNamed(document.routeName),
      trailing: Text(
        'v${document.version}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  final HydrionLegalDocument document;

  const _DocumentChip({required this.document});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: Key('legal-open-${document.id}'),
      avatar: Icon(_iconFor(document.id), size: 18),
      label: Text(document.title),
      tooltip: document.accessibilityLabel,
      onPressed: () => Navigator.of(context).pushNamed(document.routeName),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Widget? trailing;

  const _UtilityTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minVerticalPadding: 14,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('legal-app-info'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _InfoLine(
              label: 'Version',
              value: HydrionReleaseMetadata.flutterVersionName,
            ),
            const _InfoLine(
              label: 'Bundle',
              value: 'com.the1807.hydrion',
            ),
            const _InfoLine(
              label: 'Mode',
              value: 'Local-first MVP',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('legal-support-info'),
      child: ListTile(
        minVerticalPadding: 14,
        leading: const Icon(Icons.support_agent_outlined),
        title: const Text('Support'),
        subtitle: const Text(HydrionCommunityConfig.contactEmail),
        trailing: const Icon(Icons.copy_outlined),
        onTap: () async {
          await Clipboard.setData(
            const ClipboardData(text: HydrionCommunityConfig.contactEmail),
          );
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support email copied.')),
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DocumentMetadataBar extends StatelessWidget {
  final HydrionLegalDocument document;

  const _DocumentMetadataBar({required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            Text('Version ${document.version}'),
            Text('Effective ${_dateLabel(document.effectiveDate)}'),
            Text('Updated ${_dateLabel(document.lastUpdated)}'),
          ],
        ),
      ),
    );
  }
}

class _LegalMissingState extends StatelessWidget {
  const _LegalMissingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              Text(
                'Document unavailable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hydrion could not load this bundled legal document. Please return to About & Legal and try another document.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPill extends StatelessWidget {
  final String label;

  const _IntroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(HydrionRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label),
      ),
    );
  }
}

IconData _iconFor(String documentId) {
  return switch (documentId) {
    'terms' => Icons.article_outlined,
    'privacy' => Icons.privacy_tip_outlined,
    'health' => Icons.health_and_safety_outlined,
    'beta' => Icons.science_outlined,
    _ => Icons.description_outlined,
  };
}

String _stripFrontMatter(String markdown) {
  if (!markdown.startsWith('---')) {
    return markdown;
  }
  final end = markdown.indexOf('\n---', 3);
  if (end == -1) {
    return markdown;
  }
  return markdown.substring(end + 4).trimLeft();
}

String _dateLabel(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
