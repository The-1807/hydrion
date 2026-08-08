import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/locale_registry.dart';
import '../../repositories/app_locale_repository.dart';
import '../../repositories/settings_repository.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool fromSettings;

  const LanguageSelectionScreen({super.key, this.fromSettings = false});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  bool _useDevice = true;
  Locale? _selected;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<AppLocaleRepository>();
    _useDevice = repository.mode == HydrionLocaleMode.device;
    _selected ??= repository.locale;
  }

  Future<void> _continue() async {
    if (_saving || (!_useDevice && _selected == null)) return;
    setState(() => _saving = true);
    final localeRepository = context.read<AppLocaleRepository>();
    if (_useDevice) {
      await localeRepository.useDeviceLocale();
    } else {
      await localeRepository.selectLocale(_selected!);
    }
    if (!mounted) return;
    if (widget.fromSettings) {
      Navigator.of(context).pop();
      return;
    }
    final settings = context.read<UserSettingsRepository>().settings;
    Navigator.of(context).pushReplacementNamed(
      settings.onboardingCompleted ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppLocaleRepository>().locale;
    final copy = _pickerCopy(locale.languageCode);
    final options = HydrionLocaleRegistry.productionLocales;
    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(copy.body),
                  const SizedBox(height: 16),
                  RadioGroup<String>(
                    groupValue: _useDevice
                        ? 'device'
                        : HydrionLocaleRegistry.definitionFor(_selected!)
                            .languageTag,
                    onChanged: (value) {
                      if (_saving || value == null) return;
                      setState(() {
                        _useDevice = value == 'device';
                        if (!_useDevice) {
                          _selected = HydrionLocaleRegistry.locales
                              .firstWhere((item) => item.languageTag == value)
                              .locale;
                        }
                      });
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          key: const Key('language-device'),
                          value: 'device',
                          title: Text(copy.device),
                        ),
                        for (final option in options)
                          RadioListTile<String>(
                            key: Key('language-${option.languageTag}'),
                            value: option.languageTag,
                            title: Text(option.nativeName),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('language-continue'),
                  onPressed: _saving ? null : _continue,
                  child: Text(_saving ? copy.saving : copy.continueLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({
  String title,
  String body,
  String device,
  String continueLabel,
  String saving
}) _pickerCopy(String languageCode) => switch (languageCode) {
      'fr' => (
          title: 'Choisissez votre langue',
          body:
              'Vous pourrez modifier ce choix plus tard dans les r\u00e9glages.',
          device: 'Utiliser la langue de l\u2019appareil',
          continueLabel: 'Continuer',
          saving: 'Enregistrement\u2026',
        ),
      'es' => (
          title: 'Elige tu idioma',
          body: 'Puedes cambiar esta opci\u00f3n m\u00e1s tarde en Ajustes.',
          device: 'Usar el idioma del dispositivo',
          continueLabel: 'Continuar',
          saving: 'Guardando\u2026',
        ),
      _ => (
          title: 'Choose your language',
          body: 'You can change this later in Settings.',
          device: 'Use device language',
          continueLabel: 'Continue',
          saving: 'Saving\u2026',
        ),
    };
