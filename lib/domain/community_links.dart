import 'release_metadata.dart';

class HydrionCommunityLink {
  final String label;
  final Uri uri;

  const HydrionCommunityLink({
    required this.label,
    required this.uri,
  });
}

class HydrionCommunityConfig {
  static const name = HydrionReleaseMetadata.communityName;
  static const handle = HydrionReleaseMetadata.communityHandle;
  static const contactEmail = HydrionReleaseMetadata.contactEmail;

  static const externalLinks = <HydrionCommunityLink>[];

  static Uri get releaseLettersMailTo => Uri(
        scheme: 'mailto',
        path: HydrionReleaseMetadata.contactEmail,
        query: 'subject=${HydrionReleaseMetadata.releaseLettersSubject}',
      );
}
