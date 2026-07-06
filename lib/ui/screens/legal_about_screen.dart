import 'package:flutter/material.dart';

import '../../domain/community_links.dart';
import '../../domain/release_metadata.dart';
import '../theme/hydrion_design.dart';

class LegalAboutScreen extends StatelessWidget {
  const LegalAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & About'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: const [
          _IntroCard(),
          SizedBox(height: 12),
          _Section(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy Draft',
            status: HydrionReleaseMetadata.privacyStatus,
            paragraphs: [
              'Hydrion is designed as a local-first hydration companion. Hydration logs, daily goals, profile preferences, selected shark companion, local profile photo, reminders, challenge state, language preference, and legal acknowledgement are stored on this device.',
              'Hydrion does not operate an account system in this build. There is no sign-in, sign-out, username directory, friend graph, cloud backup, or Hydrion-hosted profile page.',
              'Hydrion does not sell personal data. It does not automatically enroll users in marketing or release-letter lists. Community links are opened only when the user chooses them.',
            ],
          ),
          SizedBox(height: 12),
          _ListSection(
            icon: Icons.storage_outlined,
            title: 'Data Stored On Device',
            items: [
              'Hydration log entries, including amount, timestamp, and local source label.',
              'Goal settings, unit preference, reusable container size, weather-goal mode, and last weather-goal explanation.',
              'Profile details the user enters, including display name, optional age, optional sex selection, shark avatar choice, and optional local profile photo.',
              'Reminder definitions, local notification scheduling state, challenge participation, and local app language.',
              'Recovery events used to safely handle malformed local storage without sending diagnostic data to Hydrion.',
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.location_on_outlined,
            title: 'Location, Weather, and Permissions',
            paragraphs: [
              'Weather-informed goals are optional. When enabled, Hydrion may request foreground location permission to fetch a daily forecast for the current area.',
              'Approximate latitude and longitude may be sent to the selected forecast provider, currently Open-Meteo, to retrieve weather data. Hydrion stores the resulting daily forecast summary needed for the local day, not a location-history trail.',
              'Notification permission is requested only when reminder features need operating-system notifications. Permission prompts are not shown on cold launch.',
              'If permission is denied, unavailable, stale, or unsupported, Hydrion keeps the user on their baseline goal and shows an explanatory state instead of silently changing the goal.',
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.smart_toy_outlined,
            title: 'Coach and AI Disclosure',
            paragraphs: [
              'Hydrion can run local rule-based coaching without sending hydration context to a non-local AI provider.',
              'If a non-local provider such as Gemini is configured, Hydrion keeps that provider disabled until the user grants provider privacy consent. When consent is disabled, the app falls back to local rules.',
              'Coach suggestions are informational product features. They are not medical advice and should not override professional guidance, symptoms, medication instructions, or clinician-directed fluid limits.',
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.article_outlined,
            title: 'Terms and Conditions Draft',
            status: HydrionReleaseMetadata.termsStatus,
            paragraphs: [
              'By using Hydrion, the user agrees to use the app for personal hydration tracking and routine support only. The user remains responsible for deciding what is comfortable and appropriate for their own body and circumstances.',
              'Hydrion is provided as-is in this release candidate. Features may be unavailable, inaccurate, delayed, or affected by device permissions, local storage limits, battery policies, network conditions, forecast availability, and operating-system behavior.',
              'The user is responsible for maintaining device security and for understanding that clearing app storage, uninstalling the app, or changing devices may delete local Hydrion data.',
              'Hydrion challenge content is intended to encourage gentle habits. Users must not force fluids, use challenges as competitions for excessive intake, or ignore health conditions that affect hydration needs.',
              'These draft terms require product-owner and legal approval before a public release or store listing uses them as binding terms.',
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.health_and_safety_outlined,
            title: 'Health and Safety Notice',
            status: HydrionReleaseMetadata.healthSafetyStatus,
            paragraphs: [
              'Hydrion is health-adjacent software, not a medical device. It does not diagnose, treat, cure, prevent disease, or calculate exact fluid requirements.',
              'Hydration needs vary by body, medications, medical conditions, climate, pregnancy, exercise, diet, and clinician guidance. Some people are advised to limit fluids.',
              'Stop, reduce intake, or seek medical advice if drinking more water causes discomfort, nausea, confusion, swelling, headache, dizziness, or any unusual symptom.',
              'Weather-informed goals are conservative product suggestions. They should be adjusted or ignored whenever they do not fit the user.',
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.delete_outline,
            title: 'Access, Correction, and Deletion',
            paragraphs: [
              'Profile and preference data can be edited inside Hydrion. Hydration logs can be edited or deleted from log history.',
              'Because this build is local-first and has no Hydrion account backend, users can delete Hydrion data through operating-system app-storage controls or by uninstalling the app.',
              'For support, product questions, or owner review, contact ${HydrionCommunityConfig.contactEmail}.',
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.groups_outlined,
            title: HydrionCommunityConfig.name,
            paragraphs: [
              'Community handle: ${HydrionCommunityConfig.handle}',
              'Contact: ${HydrionCommunityConfig.contactEmail}',
              'Release letters require a production, consent-aware mailing list before signup links are enabled.',
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.list_alt_outlined,
            title: 'Release Notes',
            paragraphs: [
              'v1.0.0 focuses on local hydration logging, weather-aware goal explanation, local reminders, local-only challenges, provider-guarded coaching, profile customization, and release-readiness transparency.',
              'Next planned version: ${HydrionReleaseMetadata.nextPlannedVersion}',
            ],
          ),
          SizedBox(height: 12),
          _ListSection(
            icon: Icons.warning_amber_outlined,
            title: 'Known Limitations',
            items: HydrionReleaseMetadata.knownLimitations,
          ),
          SizedBox(height: 12),
          _ListSection(
            icon: Icons.fact_check_outlined,
            title: 'Release Checklist',
            items: HydrionReleaseMetadata.releaseChecklist,
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.code_outlined,
            title: 'Licenses',
            paragraphs: [
              'Open-source licenses are available from the platform license page.',
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
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
              'A local-first hydration companion for logging water, understanding progress, and building gentler everyday routines.',
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IntroPill(
                  label: 'Version ${HydrionReleaseMetadata.flutterVersionName}',
                ),
                _IntroPill(label: HydrionReleaseMetadata.releaseDateLabel),
                _IntroPill(
                  label: 'Metadata: ${HydrionReleaseMetadata.metadataStatus}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? status;
  final List<String> paragraphs;

  const _Section({
    required this.icon,
    required this.title,
    required this.paragraphs,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 8),
            _StatusPill(label: 'Status: $status'),
          ],
          const SizedBox(height: 12),
          for (final paragraph in paragraphs) ...[
            Text(paragraph),
            if (paragraph != paragraphs.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _ListSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
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

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.pending_actions, size: 18),
      label: Text(label),
      backgroundColor: HydrionColors.sunrise.withValues(alpha: 0.18),
    );
  }
}
