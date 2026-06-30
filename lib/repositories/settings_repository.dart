import 'dart:convert';

import 'package:flutter/material.dart';

import '../storage/local_store.dart';

class UserSettings {
  final Locale locale;
  final bool nonLocalProviderConsentGranted;

  const UserSettings({
    required this.locale,
    this.nonLocalProviderConsentGranted = false,
  });

  UserSettings copyWith({
    Locale? locale,
    bool? nonLocalProviderConsentGranted,
  }) {
    return UserSettings(
      locale: locale ?? this.locale,
      nonLocalProviderConsentGranted:
          nonLocalProviderConsentGranted ?? this.nonLocalProviderConsentGranted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
      'nonLocalProviderConsentGranted': nonLocalProviderConsentGranted,
    };
  }

  static UserSettings fromJson(Object? value) {
    if (value is! Map) {
      return const UserSettings(locale: Locale('en', 'US'));
    }
    final languageCode = (value['languageCode'] ?? 'en').toString();
    final countryCode = value['countryCode']?.toString();
    return UserSettings(
      locale: Locale(
        languageCode.trim().isEmpty ? 'en' : languageCode,
        countryCode?.trim().isEmpty ?? true ? null : countryCode,
      ),
      nonLocalProviderConsentGranted:
          value['nonLocalProviderConsentGranted'] == true,
    );
  }
}

class UserSettingsRepository {
  static const storageKey = 'hydrion.user_settings.v1';

  final HydrionLocalStore _store;
  UserSettings _settings;

  UserSettingsRepository._(this._store, this._settings);

  UserSettingsRepository.memory([
    Locale locale = const Locale('en', 'US'),
    bool nonLocalProviderConsentGranted = false,
  ]) : this._(
          MemoryHydrionStore(),
          UserSettings(
            locale: locale,
            nonLocalProviderConsentGranted: nonLocalProviderConsentGranted,
          ),
        );

  static Future<UserSettingsRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return UserSettingsRepository._(
        store,
        const UserSettings(locale: Locale('en', 'US')),
      );
    }

    try {
      final decoded = jsonDecode(raw);
      return UserSettingsRepository._(store, UserSettings.fromJson(decoded));
    } on FormatException {
      return UserSettingsRepository._(
        store,
        const UserSettings(locale: Locale('en', 'US')),
      );
    }
  }

  UserSettings get settings => _settings;

  Future<void> setLocale(Locale locale) async {
    _settings = _settings.copyWith(locale: locale);
    await _persist();
  }

  Future<void> setNonLocalProviderConsentGranted(bool value) async {
    _settings = _settings.copyWith(nonLocalProviderConsentGranted: value);
    await _persist();
  }

  Future<void> _persist() async {
    await _store.writeString(storageKey, jsonEncode(_settings.toJson()));
  }
}
