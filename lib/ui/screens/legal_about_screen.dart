import 'package:flutter/material.dart';

import '../../domain/community_links.dart';
import '../../domain/release_metadata.dart';

class LegalAboutScreen extends StatelessWidget {
  const LegalAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            icon: Icons.info_outline,
            title: 'About Hydrion',
            children: [
              Text(
                'Hydrion is a local-first hydration companion for logging water, reviewing progress, and building safer everyday habits.',
              ),
              SizedBox(height: 8),
              Text(
                'Version ${HydrionReleaseMetadata.flutterVersionName}',
              ),
              Text(HydrionReleaseMetadata.releaseDateLabel),
              Text('Metadata status: ${HydrionReleaseMetadata.metadataStatus}'),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.groups_outlined,
            title: HydrionCommunityConfig.name,
            children: [
              Text('Community handle: ${HydrionCommunityConfig.handle}'),
              Text('Contact: ${HydrionCommunityConfig.contactEmail}'),
              SizedBox(height: 8),
              Text(
                'Release letters require a production, consent-aware mailing list before signup links are enabled.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            children: [
              Text(
                'Hydrion stores hydration logs, daily goal settings, reminder definitions and scheduling state, nickname, age, sex option, avatar selection, unit preference, container size, legal acknowledgement, and challenge state locally on this device.',
              ),
              SizedBox(height: 8),
              Text(
                'Weather-informed goals request foreground location only after an explanation. Coordinates are used for the selected forecast provider lookup and are not kept as a location-history trail.',
              ),
              SizedBox(height: 8),
              Text(
                'Open-Meteo forecast requests may receive approximate latitude and longitude, and Hydrion caches only the daily forecast summary needed for the current local day.',
              ),
              SizedBox(height: 8),
              Text(
                'Hydrion does not sell user data, does not sign users up for newsletters automatically, and does not send optional community links unless the user opens them.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.health_and_safety_outlined,
            title: 'Health & Safety',
            children: [
              Text(
                'Hydrion is health-adjacent software, not a medical device. It does not provide diagnosis, treatment, or exact body-need claims.',
              ),
              SizedBox(height: 8),
              Text(
                'Hydration needs vary. Stop or adjust a challenge if you feel unwell, and do not force fluids beyond your normal needs or professional health guidance.',
              ),
              SizedBox(height: 8),
              Text(
                'Status: ${HydrionReleaseMetadata.healthSafetyStatus}',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.article_outlined,
            title: 'Terms',
            children: [
              Text(
                'Draft terms are included for offline review and require owner/legal approval before public publication.',
              ),
              SizedBox(height: 8),
              Text(
                'Use Hydrion responsibly, keep your own device secure, and review data before deleting local app storage.',
              ),
              SizedBox(height: 8),
              Text('Status: ${HydrionReleaseMetadata.termsStatus}'),
              Text('Privacy status: ${HydrionReleaseMetadata.privacyStatus}'),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.list_alt_outlined,
            title: 'Release Notes',
            children: [
              Text(
                'v1.0.0 focuses on local hydration logging, daily goals, local settings, local-only challenges, provider-guarded coaching, and release-readiness transparency.',
              ),
              SizedBox(height: 8),
              Text(
                  'Next planned version: ${HydrionReleaseMetadata.nextPlannedVersion}'),
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
            icon: Icons.delete_outline,
            title: 'Delete or Reset Local Data',
            children: [
              Text(
                'Use the operating system app-storage controls to remove local Hydrion data. Hydration history is not sent to a Hydrion backend in this build.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.code_outlined,
            title: 'Licenses',
            children: [
              Text(
                'Open-source licenses are available from the platform license page.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
    return _Section(
      icon: icon,
      title: title,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}
