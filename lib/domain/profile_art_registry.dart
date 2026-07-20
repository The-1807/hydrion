import '../repositories/settings_repository.dart';

/// The only profile classifications that may influence Hydrion artwork.
enum HydrionProfileArtPresentation { male, female, neutral }

/// A profile-aware artwork slot with an explicit, non-gendered fallback.
class HydrionProfileArtSlot {
  final String neutralAsset;
  final String? maleAsset;
  final String? femaleAsset;
  final String? intersexAsset;

  const HydrionProfileArtSlot({
    required this.neutralAsset,
    this.maleAsset,
    this.femaleAsset,
    this.intersexAsset,
  });
}

/// Centralizes profile normalization and prevents implicit Male fallbacks.
class HydrionProfileArtResolver {
  const HydrionProfileArtResolver._();

  static HydrionProfileArtPresentation presentationFor(Object? profileValue) {
    final normalized = switch (profileValue) {
      HydrionSex value => value.name,
      String value =>
        value.trim().toLowerCase().replaceAll(RegExp(r'[_\s-]'), ''),
      _ => '',
    };
    return switch (normalized) {
      'male' => HydrionProfileArtPresentation.male,
      'female' => HydrionProfileArtPresentation.female,
      _ => HydrionProfileArtPresentation.neutral,
    };
  }

  static String resolve({
    required Object? profileValue,
    required HydrionProfileArtSlot slot,
  }) {
    if (_isIntersex(profileValue) && slot.intersexAsset != null) {
      return slot.intersexAsset!;
    }
    return switch (presentationFor(profileValue)) {
      HydrionProfileArtPresentation.male => slot.maleAsset ?? slot.neutralAsset,
      HydrionProfileArtPresentation.female =>
        slot.femaleAsset ?? slot.neutralAsset,
      HydrionProfileArtPresentation.neutral => slot.neutralAsset,
    };
  }

  static bool _isIntersex(Object? profileValue) {
    if (profileValue == HydrionSex.intersex) return true;
    if (profileValue is! String) return false;
    return profileValue
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[_\s-]'), '') ==
        'intersex';
  }
}
