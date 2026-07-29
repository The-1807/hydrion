import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/life_stage_policy.dart';

void main() {
  group('HydrionLifeStagePolicy', () {
    test('separates product access boundaries', () {
      expect(
        HydrionLifeStagePolicy.productAccessStage(12),
        HydrionProductAccessStage.unsupportedIndependentChild,
      );
      expect(
        HydrionLifeStagePolicy.productAccessStage(13),
        HydrionProductAccessStage.teen,
      );
      expect(
        HydrionLifeStagePolicy.productAccessStage(17),
        HydrionProductAccessStage.teen,
      );
      expect(
        HydrionLifeStagePolicy.productAccessStage(18),
        HydrionProductAccessStage.adult,
      );
    });

    test('separates adolescent and adult body reference boundaries', () {
      expect(
        HydrionLifeStagePolicy.bodyReferenceStage(19),
        HydrionBodyReferenceStage.adolescent,
      );
      expect(
        HydrionLifeStagePolicy.bodyReferenceStage(20),
        HydrionBodyReferenceStage.adult,
      );
    });

    test('handles missing and corrupt ages without inventing a stage', () {
      expect(
        HydrionLifeStagePolicy.productAccessStage(null),
        HydrionProductAccessStage.unresolved,
      );
      expect(
        HydrionLifeStagePolicy.productAccessStage(-1),
        HydrionProductAccessStage.invalid,
      );
      expect(
        HydrionLifeStagePolicy.productAccessStage(121),
        HydrionProductAccessStage.invalid,
      );
    });
  });
}
