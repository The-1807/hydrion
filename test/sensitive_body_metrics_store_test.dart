import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/storage/local_store.dart';

/// Regression coverage for the HYD-SEC-001 remediation: sensitive body
/// metrics (weight, height, reproductive state, pregnancy duration, fluid
/// safety mode, clinician target) must migrate out of plaintext local
/// storage into Keychain/Keystore-backed secure storage, safely,
/// idempotently, and without ever silently losing data — per
/// `HYD_SEC_001_STORAGE_DESIGN.md` and the Gate 1 report.
void main() {
  const migrationMarkerKey = 'hydrion.body_metrics.secure_migration.v1';

  test('new install: sensitive fields go straight to secure storage', () async {
    final plaintext = MemoryHydrionStore();
    final secure = MemorySensitiveBodyMetricsStore();
    final repository = await BodyMetricsRepository.load(
      plaintext,
      secureStore: secure,
    );

    await repository.save(
      const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 175,
        fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
        clinicianTargetMl: 1800,
      ),
      femaleProfile: false,
    );

    final secureValue = await secure.read();
    expect(secureValue, isNotNull);
    expect(secureValue!['weightKg'], 70);
    expect(secureValue['clinicianTargetMl'], 1800);

    final plaintextJson = jsonDecode(
      plaintext.snapshot[BodyMetricsRepository.storageKey]!,
    ) as Map;
    expect(plaintextJson['weightKg'], isNull);
    expect(plaintextJson['clinicianTargetMl'], isNull);
    expect(plaintextJson['fluidSafetyMode'], 'none');
    expect(plaintext.snapshot[migrationMarkerKey], 'completed');
  });

  test(
    'upgrade: existing plaintext sensitive values migrate on load and are '
    'stripped from plaintext only on a subsequent, later load',
    () async {
      final plaintext = MemoryHydrionStore({
        BodyMetricsRepository.storageKey: jsonEncode({
          'schemaVersion': 3,
          'personalizationEnabled': true,
          'weightKg': 68,
          'heightCm': 171,
          'reproductiveState': 'pregnant',
          'pregnancyGestationalDays': 140,
          'fluidSafetyMode': 'clinicianTarget',
          'clinicianTargetMl': 2000,
          'allowAdjustmentsAboveClinicianTarget': false,
        }),
      });
      final secure = MemorySensitiveBodyMetricsStore();

      // First load: migrates and verifies, but must NOT strip plaintext on
      // this same run (crash-safety — see BodyMetricsRepository docs).
      final firstLoad = await BodyMetricsRepository.load(
        plaintext,
        secureStore: secure,
      );
      expect(firstLoad.metrics.weightKg, 68);
      expect(firstLoad.metrics.clinicianTargetMl, 2000);
      expect((await secure.read())!['weightKg'], 68);
      expect(plaintext.snapshot[migrationMarkerKey], 'completed');
      final afterFirstLoad = jsonDecode(
        plaintext.snapshot[BodyMetricsRepository.storageKey]!,
      ) as Map;
      expect(
        afterFirstLoad['weightKg'],
        68,
        reason: 'plaintext original must survive the same run that first '
            'wrote the secure copy',
      );

      // Second load (a later, separate app start): now safe to strip.
      final secondLoad = await BodyMetricsRepository.load(
        plaintext,
        secureStore: secure,
      );
      expect(secondLoad.metrics.weightKg, 68);
      expect(secondLoad.metrics.clinicianTargetMl, 2000);
      expect(secondLoad.metrics.reproductiveState,
          HydrionReproductiveHydrationState.pregnant);
      final afterSecondLoad = jsonDecode(
        plaintext.snapshot[BodyMetricsRepository.storageKey]!,
      ) as Map;
      expect(afterSecondLoad['weightKg'], isNull);
      expect(afterSecondLoad['clinicianTargetMl'], isNull);
      expect(afterSecondLoad['reproductiveState'], 'none');
    },
  );

  test(
    'migration is idempotent: repeated loads never duplicate work or '
    'corrupt already-migrated fields',
    () async {
      final plaintext = MemoryHydrionStore({
        BodyMetricsRepository.storageKey: jsonEncode({
          'schemaVersion': 3,
          'weightKg': 70,
          'heightCm': 175,
        }),
      });
      final secure = MemorySensitiveBodyMetricsStore();

      for (var i = 0; i < 4; i++) {
        final repository = await BodyMetricsRepository.load(
          plaintext,
          secureStore: secure,
        );
        expect(repository.metrics.weightKg, 70);
        expect(repository.metrics.heightCm, 175);
      }
      expect(plaintext.snapshot[migrationMarkerKey], 'completed');
    },
  );

  test(
    'a failed/unavailable secure write never loses data: plaintext stays '
    'intact and authoritative',
    () async {
      final plaintext = MemoryHydrionStore({
        BodyMetricsRepository.storageKey: jsonEncode({
          'schemaVersion': 3,
          'weightKg': 70,
          'heightCm': 175,
          'clinicianTargetMl': 1900,
          'fluidSafetyMode': 'clinicianTarget',
        }),
      });
      // supported: false simulates a platform with no Keychain/Keystore,
      // or a store whose writes never succeed.
      final unavailableSecure =
          MemorySensitiveBodyMetricsStore(supported: false);

      final repository = await BodyMetricsRepository.load(
        plaintext,
        secureStore: unavailableSecure,
      );
      expect(repository.metrics.weightKg, 70);
      expect(repository.metrics.clinicianTargetMl, 1900);
      expect(plaintext.snapshot[migrationMarkerKey], isNull);
      final json = jsonDecode(
        plaintext.snapshot[BodyMetricsRepository.storageKey]!,
      ) as Map;
      expect(json['weightKg'], 70, reason: 'nothing may be stripped when '
          'the secure copy could not be verified');
      expect(json['clinicianTargetMl'], 1900);

      // Subsequent saves must also keep falling back to full plaintext
      // rather than silently dropping the sensitive fields.
      final saved = await repository.update(
        weightKg: 71,
        femaleProfile: false,
      );
      expect(saved, isTrue);
      expect(repository.metrics.clinicianTargetMl, 1900);
      final resaved = jsonDecode(
        plaintext.snapshot[BodyMetricsRepository.storageKey]!,
      ) as Map;
      expect(resaved['weightKg'], 71);
      expect(resaved['clinicianTargetMl'], 1900);
    },
  );

  test(
    'corrupted legacy data in a sensitive field is skipped, not crashed on '
    'or invented',
    () async {
      final plaintext = MemoryHydrionStore({
        BodyMetricsRepository.storageKey:
            '{"schemaVersion":3,"weightKg":"not-a-number","heightCm":175,'
                '"clinicianTargetMl":"also-bad"}',
      });
      final secure = MemorySensitiveBodyMetricsStore();

      final repository = await BodyMetricsRepository.load(
        plaintext,
        secureStore: secure,
      );
      expect(repository.metrics.weightKg, isNull);
      expect(repository.metrics.heightCm, 175);
      expect(repository.metrics.clinicianTargetMl, isNull);
    },
  );

  test(
    'clear() removes the plaintext record, the migration marker, and the '
    'secure copy together',
    () async {
      final plaintext = MemoryHydrionStore();
      final secure = MemorySensitiveBodyMetricsStore();
      final repository = await BodyMetricsRepository.load(
        plaintext,
        secureStore: secure,
      );
      await repository.save(
        const HydrionBodyMetrics(weightKg: 70, clinicianTargetMl: 1800),
        femaleProfile: false,
      );
      expect(await secure.read(), isNotNull);

      await repository.clear();

      expect(await secure.read(), isNull);
      expect(
        plaintext.snapshot.containsKey(BodyMetricsRepository.storageKey),
        isFalse,
      );
      expect(plaintext.snapshot.containsKey(migrationMarkerKey), isFalse);
      expect(repository.metrics.weightKg, isNull);
    },
  );

  test(
    'secure storage already populated (e.g. after reinstall/restore) still '
    'strips any lingering plaintext on the next load',
    () async {
      final plaintext = MemoryHydrionStore({
        BodyMetricsRepository.storageKey: jsonEncode({
          'schemaVersion': 3,
          'weightKg': 65,
        }),
      });
      final secure = MemorySensitiveBodyMetricsStore(
        initial: const {
          'weightKg': 65.0,
          'heightCm': null,
          'reproductiveState': 'none',
          'pregnancyGestationalDays': null,
          'fluidSafetyMode': 'none',
          'clinicianTargetMl': null,
          'allowAdjustmentsAboveClinicianTarget': false,
        },
      );

      final repository = await BodyMetricsRepository.load(
        plaintext,
        secureStore: secure,
      );
      expect(repository.metrics.weightKg, 65);
      final json = jsonDecode(
        plaintext.snapshot[BodyMetricsRepository.storageKey]!,
      ) as Map;
      expect(json['weightKg'], isNull);
    },
  );
}
