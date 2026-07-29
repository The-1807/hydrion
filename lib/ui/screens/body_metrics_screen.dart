import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/body_metrics.dart';
import '../../domain/daily_hydration_context.dart';
import '../../domain/hydration_recommendation.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/body_metrics_repository.dart';
import '../../repositories/daily_hydration_context_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/daily_hydration_recommendation_coordinator.dart';

class BodyMetricsScreen extends StatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  State<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen> {
  bool _initialized = false;
  late bool _enabled;
  late bool _usePersonalizedBaseline;
  late bool _weatherEnabled;
  late double _weightKg;
  late double _heightCm;
  late HydrionWeightUnit _weightUnit;
  late HydrionHeightUnit _heightUnit;
  late HydrionReproductiveHydrationState _reproductiveState;
  late HydrionPregnancyDurationUnit _pregnancyDurationUnit;
  int? _pregnancyGestationalDays;
  final _pregnancyDuration = TextEditingController();
  String? _pregnancyDurationError;
  late HydrionFluidSafetyMode _safetyMode;
  late bool _allowAboveTarget;
  final _clinicianTarget = TextEditingController();
  final _manualWeight = TextEditingController();
  final _manualHeight = TextEditingController();
  late HydrionActivityIntensity _intensity;
  late HydrionEnvironmentExposure _environment;
  late HydrionSweatLevel _sweat;
  late HydrionTemporaryCondition _condition;
  final _activityMinutes = TextEditingController();
  HydrationRecommendation? _recommendation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final metrics = context.read<BodyMetricsRepository>().metrics;
    final settings = context.read<UserSettingsRepository>().settings;
    final now = DateTime.now();
    final daily = context
        .read<DailyHydrationContextRepository>()
        .forDate(hydrionLocalDateKey(now));
    _enabled = metrics.personalizationEnabled;
    _usePersonalizedBaseline =
        settings.baselineSource == HydrionBaselineSource.personalized;
    _weatherEnabled = settings.weatherModifierEnabled;
    _weightKg = metrics.weightKg ?? 70;
    _heightCm = metrics.heightCm ?? 170;
    _weightUnit = metrics.preferredWeightUnit;
    _heightUnit = metrics.preferredHeightUnit;
    _reproductiveState = metrics.reproductiveState;
    _pregnancyDurationUnit = metrics.preferredPregnancyDurationUnit;
    _pregnancyGestationalDays = metrics.pregnancyGestationalDays;
    _syncPregnancyDurationField();
    _safetyMode = metrics.fluidSafetyMode;
    _allowAboveTarget = metrics.allowAdjustmentsAboveClinicianTarget;
    _clinicianTarget.text = metrics.clinicianTargetMl?.toString() ?? '';
    _syncManualFields();
    _intensity = daily?.activityIntensity ?? HydrionActivityIntensity.rest;
    _environment =
        daily?.environment ?? HydrionEnvironmentExposure.mostlyIndoors;
    _sweat = daily?.sweatLevel ?? HydrionSweatLevel.unknown;
    _condition = daily?.temporaryCondition ?? HydrionTemporaryCondition.none;
    _activityMinutes.text = (daily?.activityMinutes ?? 0).toString();
  }

  @override
  void dispose() {
    _clinicianTarget.dispose();
    _manualWeight.dispose();
    _manualHeight.dispose();
    _activityMinutes.dispose();
    _pregnancyDuration.dispose();
    super.dispose();
  }

  void _syncManualFields() {
    _manualWeight.text = (_weightUnit == HydrionWeightUnit.kilograms
            ? _weightKg
            : HydrionBodyMetricsPolicy.kilogramsToPounds(_weightKg))
        .toStringAsFixed(1);
    _manualHeight.text = (_heightUnit == HydrionHeightUnit.centimetres
            ? _heightCm
            : HydrionBodyMetricsPolicy.centimetresToInches(_heightCm))
        .toStringAsFixed(1);
  }

  void _syncPregnancyDurationField() {
    final days = _pregnancyGestationalDays;
    if (days == null) {
      _pregnancyDuration.text = '';
      return;
    }
    final value = switch (_pregnancyDurationUnit) {
      HydrionPregnancyDurationUnit.days => days.toDouble(),
      HydrionPregnancyDurationUnit.weeks =>
        HydrionBodyMetricsPolicy.pregnancyDaysToWeeks(days),
      HydrionPregnancyDurationUnit.months =>
        HydrionBodyMetricsPolicy.pregnancyDaysToMonths(days),
    };
    _pregnancyDuration.text = _displayDuration(value);
  }

  String _displayDuration(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  int? _parsePregnancyDuration() {
    final raw = _pregnancyDuration.text.trim();
    final value = double.tryParse(raw);
    if (raw.isEmpty || value == null || !value.isFinite || value <= 0) {
      return null;
    }
    final days = switch (_pregnancyDurationUnit) {
      HydrionPregnancyDurationUnit.days =>
        value == value.roundToDouble() ? value.round() : null,
      HydrionPregnancyDurationUnit.weeks =>
        HydrionBodyMetricsPolicy.pregnancyWeeksToDays(value),
      HydrionPregnancyDurationUnit.months =>
        HydrionBodyMetricsPolicy.pregnancyMonthsToDays(value),
    };
    return HydrionBodyMetricsPolicy.validPregnancyDays(days) ? days : null;
  }

  Future<void> _saveMetrics() async {
    final l10n = AppLocalizations.of(context);
    if (_reproductiveState == HydrionReproductiveHydrationState.pregnant) {
      final days = _parsePregnancyDuration();
      if (days == null) {
        setState(() => _pregnancyDurationError = l10n.pregnancyDurationInvalid);
        return;
      }
      _pregnancyGestationalDays = days;
    }
    final settings = context.read<UserSettingsRepository>().settings;
    final target = int.tryParse(_clinicianTarget.text.trim());
    final saved = await context.read<BodyMetricsRepository>().save(
          HydrionBodyMetrics(
            personalizationEnabled: _enabled,
            weightKg: _enabled ? _weightKg : null,
            heightCm: _enabled ? _heightCm : null,
            preferredWeightUnit: _weightUnit,
            preferredHeightUnit: _heightUnit,
            reproductiveState: settings.sex == HydrionSex.female
                ? _reproductiveState
                : HydrionReproductiveHydrationState.none,
            pregnancyGestationalDays:
                _reproductiveState == HydrionReproductiveHydrationState.pregnant
                    ? _pregnancyGestationalDays
                    : null,
            preferredPregnancyDurationUnit: _pregnancyDurationUnit,
            fluidSafetyMode: _safetyMode,
            clinicianTargetMl:
                _safetyMode == HydrionFluidSafetyMode.clinicianTarget
                    ? target
                    : null,
            allowAdjustmentsAboveClinicianTarget: _allowAboveTarget,
          ),
          femaleProfile: settings.sex == HydrionSex.female,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? l10n.bodyMetricsSaved : l10n.bodyMetricsInvalid),
      ),
    );
    if (saved) {
      await context.read<UserSettingsRepository>().setPersonalizedGoalOptions(
            baselineSource: _usePersonalizedBaseline
                ? HydrionBaselineSource.personalized
                : HydrionBaselineSource.manual,
            weatherModifierEnabled: _weatherEnabled,
          );
      await _refreshRecommendation();
    }
  }

  Future<void> _deleteMetrics() async {
    final l10n = AppLocalizations.of(context);
    final bodyRepository = context.read<BodyMetricsRepository>();
    final settingsRepository = context.read<UserSettingsRepository>();
    final settings = settingsRepository.settings;
    await bodyRepository.clear();
    await settingsRepository.setPersonalizedGoalOptions(
      baselineSource: HydrionBaselineSource.manual,
      weatherModifierEnabled: settings.weatherModifierEnabled,
    );
    if (!mounted) return;
    setState(() {
      _enabled = false;
      _reproductiveState = HydrionReproductiveHydrationState.none;
      _pregnancyGestationalDays = null;
      _pregnancyDuration.clear();
      _pregnancyDurationError = null;
      _recommendation = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.bodyMetricsDeleted)));
  }

  Future<void> _saveContext() async {
    final minutes = int.tryParse(_activityMinutes.text.trim()) ?? -1;
    if (minutes < 0 || minutes > 1440) return;
    final now = DateTime.now();
    await context.read<DailyHydrationContextRepository>().save(
          DailyHydrationContext(
            localDateKey: hydrionLocalDateKey(now),
            activityIntensity: _intensity,
            activityMinutes: minutes,
            environment: _environment,
            sweatLevel: _sweat,
            temporaryCondition: _condition,
            updatedAt: now,
          ),
        );
    await _refreshRecommendation();
  }

  Future<void> _refreshRecommendation() async {
    final recommendation = await context
        .read<DailyHydrationRecommendationCoordinator>()
        .calculate(now: DateTime.now());
    if (mounted) setState(() => _recommendation = recommendation);
  }

  Future<void> _applyRecommendation() async {
    final recommendation = _recommendation;
    if (recommendation == null) return;
    await context
        .read<DailyHydrationRecommendationCoordinator>()
        .apply(recommendation, now: DateTime.now());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<UserSettingsRepository>().settings;
    final metrics =
        HydrionBodyMetrics(weightKg: _weightKg, heightCm: _heightCm);
    final bmi = metrics.adultBmi;
    final category = adultBmiCategory(age: settings.age, bmi: bmi);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bodyMetricsTitle)),
      body: SafeArea(
        child: ListView(
          key: const Key('body-metrics-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(l10n.bodyMetricsOptional),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('body-metrics-enabled'),
              value: _enabled,
              title: Text(l10n.enablePersonalization),
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile(
              key: const Key('personalized-baseline-option'),
              value: _usePersonalizedBaseline,
              title: Text(l10n.personalizedBaselineOption),
              subtitle: Text(l10n.personalizedBaselineHelp),
              onChanged: _enabled
                  ? (value) => setState(() => _usePersonalizedBaseline = value)
                  : null,
            ),
            SwitchListTile(
              key: const Key('weather-modifier-option'),
              value: _weatherEnabled,
              title: Text(l10n.weatherModifierOption),
              onChanged: (value) => setState(() => _weatherEnabled = value),
            ),
            if (_enabled) ...[
              _MetricWheel(
                key: const Key('weight-wheel'),
                title: l10n.weightLabel,
                valueCount: 2751,
                initialIndex: ((_weightKg - 25) * 10).round().clamp(0, 2750),
                labelAt: (index) {
                  final kg = 25 + index / 10;
                  return _weightUnit == HydrionWeightUnit.kilograms
                      ? '${kg.toStringAsFixed(1)} ${l10n.kilogramsLabel}'
                      : '${HydrionBodyMetricsPolicy.kilogramsToPounds(kg).toStringAsFixed(1)} ${l10n.poundsLabel}';
                },
                onChanged: (index) {
                  setState(() {
                    _weightKg = 25 + index / 10;
                    _syncManualFields();
                  });
                },
                unitControl: SegmentedButton<HydrionWeightUnit>(
                  selected: {_weightUnit},
                  segments: [
                    ButtonSegment(
                      value: HydrionWeightUnit.kilograms,
                      label: Text(l10n.kilogramsLabel),
                    ),
                    ButtonSegment(
                      value: HydrionWeightUnit.pounds,
                      label: Text(l10n.poundsLabel),
                    ),
                  ],
                  onSelectionChanged: (selection) => setState(() {
                    _weightUnit = selection.single;
                    _syncManualFields();
                  }),
                ),
              ),
              _MetricWheel(
                key: const Key('height-wheel'),
                title: l10n.heightLabel,
                valueCount: 111,
                initialIndex: (_heightCm - 120).round().clamp(0, 110),
                labelAt: (index) {
                  final cm = 120.0 + index;
                  if (_heightUnit == HydrionHeightUnit.centimetres) {
                    return '${cm.round()} ${l10n.centimetresLabel}';
                  }
                  final inches =
                      HydrionBodyMetricsPolicy.centimetresToInches(cm).round();
                  return '${inches ~/ 12}′ ${inches % 12}″';
                },
                onChanged: (index) {
                  setState(() {
                    _heightCm = 120.0 + index;
                    _syncManualFields();
                  });
                },
                unitControl: SegmentedButton<HydrionHeightUnit>(
                  selected: {_heightUnit},
                  segments: [
                    ButtonSegment(
                      value: HydrionHeightUnit.centimetres,
                      label: Text(l10n.centimetresLabel),
                    ),
                    ButtonSegment(
                      value: HydrionHeightUnit.feetAndInches,
                      label: Text(l10n.feetInchesLabel),
                    ),
                  ],
                  onSelectionChanged: (selection) => setState(() {
                    _heightUnit = selection.single;
                    _syncManualFields();
                  }),
                ),
              ),
              ExpansionTile(
                title: Text('${l10n.weightLabel} / ${l10n.heightLabel}'),
                subtitle: Text(l10n.accessibleNumericEntry),
                children: [
                  TextField(
                    controller: _manualWeight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText:
                          '${l10n.weightLabel} (${_weightUnit == HydrionWeightUnit.kilograms ? l10n.kilogramsLabel : l10n.poundsLabel})',
                    ),
                    onChanged: (value) {
                      final entered = double.tryParse(value);
                      if (entered == null) return;
                      final kg = _weightUnit == HydrionWeightUnit.kilograms
                          ? entered
                          : HydrionBodyMetricsPolicy.poundsToKilograms(entered);
                      if (HydrionBodyMetricsPolicy.validWeight(kg)) {
                        setState(() => _weightKg = kg);
                      }
                    },
                  ),
                  TextField(
                    controller: _manualHeight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText:
                          '${l10n.heightLabel} (${_heightUnit == HydrionHeightUnit.centimetres ? l10n.centimetresLabel : l10n.inchesLabel})',
                    ),
                    onChanged: (value) {
                      final entered = double.tryParse(value);
                      if (entered == null) return;
                      final cm = _heightUnit == HydrionHeightUnit.centimetres
                          ? entered
                          : HydrionBodyMetricsPolicy.inchesToCentimetres(
                              entered);
                      if (HydrionBodyMetricsPolicy.validHeight(cm)) {
                        setState(() => _heightCm = cm);
                      }
                    },
                  ),
                ],
              ),
              _BmiCard(
                bmi: bmi,
                category: category,
                age: settings.age,
              ),
            ],
            if (settings.sex == HydrionSex.female)
              DropdownButtonFormField<HydrionReproductiveHydrationState>(
                key: const Key('reproductive-state'),
                initialValue: _reproductiveState,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: l10n.reproductiveHydrationTitle),
                items: HydrionReproductiveHydrationState.values
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_reproductiveLabel(l10n, value)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _reproductiveState = value!;
                  if (value != HydrionReproductiveHydrationState.pregnant) {
                    _pregnancyGestationalDays = null;
                    _pregnancyDuration.clear();
                    _pregnancyDurationError = null;
                  }
                }),
              ),
            if (settings.sex == HydrionSex.female &&
                _reproductiveState ==
                    HydrionReproductiveHydrationState.pregnant)
              _PregnancyDurationEditor(
                unit: _pregnancyDurationUnit,
                controller: _pregnancyDuration,
                errorText: _pregnancyDurationError,
                canonicalDays: _pregnancyGestationalDays,
                onUnitChanged: (unit) => setState(() {
                  final entered = _parsePregnancyDuration();
                  if (entered != null) {
                    _pregnancyGestationalDays = entered;
                  }
                  _pregnancyDurationUnit = unit;
                  _syncPregnancyDurationField();
                  _pregnancyDurationError = null;
                }),
                onChanged: (_) => setState(() {
                  _pregnancyGestationalDays = _parsePregnancyDuration();
                  _pregnancyDurationError = null;
                }),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HydrionFluidSafetyMode>(
              key: const Key('fluid-safety-mode'),
              initialValue: _safetyMode,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.fluidSafetyTitle),
              items: HydrionFluidSafetyMode.values
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(_safetyLabel(l10n, value)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _safetyMode = value!),
            ),
            if (_safetyMode == HydrionFluidSafetyMode.clinicianTarget) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('clinician-target'),
                controller: _clinicianTarget,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: l10n.clinicianTargetLabel),
              ),
              CheckboxListTile(
                value: _allowAboveTarget,
                title: Text(l10n.allowAboveClinicianTarget),
                onChanged: (value) =>
                    setState(() => _allowAboveTarget = value ?? false),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('save-body-metrics'),
              onPressed: _saveMetrics,
              child: Text(l10n.saveBodyMetrics),
            ),
            TextButton(
              key: const Key('delete-body-metrics'),
              onPressed: _deleteMetrics,
              child: Text(l10n.deleteBodyMetrics),
            ),
            const Divider(height: 32),
            Text(l10n.dailyContextTitle,
                style: Theme.of(context).textTheme.titleLarge),
            Text(l10n.dailyContextOptional),
            const SizedBox(height: 12),
            _DailyContextEditor(
              intensity: _intensity,
              environment: _environment,
              sweat: _sweat,
              condition: _condition,
              minutesController: _activityMinutes,
              onIntensity: (value) => setState(() => _intensity = value),
              onEnvironment: (value) => setState(() => _environment = value),
              onSweat: (value) => setState(() => _sweat = value),
              onCondition: (value) => setState(() => _condition = value),
              onSave: _saveContext,
              onClear: () async {
                final now = DateTime.now();
                await context
                    .read<DailyHydrationContextRepository>()
                    .remove(hydrionLocalDateKey(now));
                await _refreshRecommendation();
              },
            ),
            const Divider(height: 32),
            _RecommendationCard(
              recommendation: _recommendation,
              onReview: _refreshRecommendation,
              onApply: _applyRecommendation,
            ),
          ],
        ),
      ),
    );
  }
}

class _PregnancyDurationEditor extends StatelessWidget {
  final HydrionPregnancyDurationUnit unit;
  final TextEditingController controller;
  final String? errorText;
  final int? canonicalDays;
  final ValueChanged<HydrionPregnancyDurationUnit> onUnitChanged;
  final ValueChanged<String> onChanged;

  const _PregnancyDurationEditor({
    required this.unit,
    required this.controller,
    required this.errorText,
    required this.canonicalDays,
    required this.onUnitChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weeks = canonicalDays == null ? null : canonicalDays! ~/ 7;
    final days = canonicalDays == null ? null : canonicalDays! % 7;
    return Padding(
      key: const Key('pregnancy-duration-editor'),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.pregnancyDurationTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<HydrionPregnancyDurationUnit>(
            key: const Key('pregnancy-duration-unit'),
            selected: {unit},
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: HydrionPregnancyDurationUnit.days,
                label: Text(l10n.pregnancyDurationDays),
              ),
              ButtonSegment(
                value: HydrionPregnancyDurationUnit.weeks,
                label: Text(l10n.pregnancyDurationWeeks),
              ),
              ButtonSegment(
                value: HydrionPregnancyDurationUnit.months,
                label: Text(l10n.pregnancyDurationMonths),
              ),
            ],
            onSelectionChanged: (selection) => onUnitChanged(selection.single),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('pregnancy-duration-input'),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.pregnancyDurationInputLabel,
              helperText: unit == HydrionPregnancyDurationUnit.months
                  ? l10n.pregnancyDurationMonthsHelp
                  : l10n.pregnancyDurationHelp,
              errorText: errorText,
            ),
            onChanged: onChanged,
          ),
          if (weeks != null && days != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.pregnancyDurationSummary(weeks: weeks, days: days),
                  key: const Key('pregnancy-duration-summary'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricWheel extends StatelessWidget {
  final String title;
  final int valueCount;
  final int initialIndex;
  final String Function(int) labelAt;
  final ValueChanged<int> onChanged;
  final Widget unitControl;

  const _MetricWheel({
    super.key,
    required this.title,
    required this.valueCount,
    required this.initialIndex,
    required this.labelAt,
    required this.onChanged,
    required this.unitControl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              Flexible(
                  child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: unitControl,
              )),
            ]),
            SizedBox(
              height: 132,
              child: CupertinoPicker.builder(
                scrollController:
                    FixedExtentScrollController(initialItem: initialIndex),
                itemExtent: 42,
                useMagnifier: true,
                magnification: 1.08,
                onSelectedItemChanged: onChanged,
                childCount: valueCount,
                itemBuilder: (_, index) => Center(
                  child: Semantics(
                    value: labelAt(index),
                    child: Text(labelAt(index)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final double? bmi;
  final HydrionAdultBmiCategory? category;
  final int? age;

  const _BmiCard(
      {required this.bmi, required this.category, required this.age});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('bmi-card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.bmiTitle, style: Theme.of(context).textTheme.titleMedium),
          if (bmi != null) Text(bmi!.toStringAsFixed(1)),
          if (age != null && age! < 20)
            Text(l10n.bmiUnderTwenty)
          else if (category != null)
            Text(_bmiCategoryLabel(l10n, category!)),
          const SizedBox(height: 8),
          Text(l10n.bmiDisclaimer),
        ]),
      ),
    );
  }
}

class _DailyContextEditor extends StatelessWidget {
  final HydrionActivityIntensity intensity;
  final HydrionEnvironmentExposure environment;
  final HydrionSweatLevel sweat;
  final HydrionTemporaryCondition condition;
  final TextEditingController minutesController;
  final ValueChanged<HydrionActivityIntensity> onIntensity;
  final ValueChanged<HydrionEnvironmentExposure> onEnvironment;
  final ValueChanged<HydrionSweatLevel> onSweat;
  final ValueChanged<HydrionTemporaryCondition> onCondition;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const _DailyContextEditor({
    required this.intensity,
    required this.environment,
    required this.sweat,
    required this.condition,
    required this.minutesController,
    required this.onIntensity,
    required this.onEnvironment,
    required this.onSweat,
    required this.onCondition,
    required this.onSave,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(children: [
      DropdownButtonFormField<HydrionActivityIntensity>(
        initialValue: intensity,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.activityIntensityLabel),
        items: HydrionActivityIntensity.values
            .map((value) => DropdownMenuItem(
                value: value, child: Text(_activityLabel(l10n, value))))
            .toList(),
        onChanged: (value) => onIntensity(value!),
      ),
      TextField(
        key: const Key('activity-minutes'),
        controller: minutesController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: l10n.activityMinutesLabel),
      ),
      DropdownButtonFormField<HydrionEnvironmentExposure>(
        initialValue: environment,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.environmentLabel),
        items: HydrionEnvironmentExposure.values
            .map((value) => DropdownMenuItem(
                value: value, child: Text(_environmentLabel(l10n, value))))
            .toList(),
        onChanged: (value) => onEnvironment(value!),
      ),
      DropdownButtonFormField<HydrionSweatLevel>(
        initialValue: sweat,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.sweatLevelLabel),
        items: HydrionSweatLevel.values
            .map((value) => DropdownMenuItem(
                value: value, child: Text(_sweatLabel(l10n, value))))
            .toList(),
        onChanged: (value) => onSweat(value!),
      ),
      DropdownButtonFormField<HydrionTemporaryCondition>(
        initialValue: condition,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.temporaryConditionLabel),
        items: HydrionTemporaryCondition.values
            .map((value) => DropdownMenuItem(
                value: value, child: Text(_conditionLabel(l10n, value))))
            .toList(),
        onChanged: (value) => onCondition(value!),
      ),
      if (condition != HydrionTemporaryCondition.none &&
          condition != HydrionTemporaryCondition.preferNotToSay)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(l10n.illnessSafetyNotice),
        ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton(onPressed: onSave, child: Text(l10n.saveDailyContext)),
        OutlinedButton(onPressed: onClear, child: Text(l10n.clearDailyContext)),
      ]),
    ]);
  }
}

class _RecommendationCard extends StatelessWidget {
  final HydrationRecommendation? recommendation;
  final VoidCallback onReview;
  final VoidCallback onApply;

  const _RecommendationCard({
    required this.recommendation,
    required this.onReview,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = recommendation;
    return Card(
      key: const Key('hydration-recommendation-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.hydrationSuggestionTitle,
              style: Theme.of(context).textTheme.titleLarge),
          if (result != null) ...[
            Text('${result.roundedRecommendedGoalMl} mL'),
            Text('${l10n.baselineLabel}: ${result.baselineGoalMl} mL'),
            Text(
              '${l10n.adjustmentsLabel}: '
              '${result.reproductiveAdjustmentMl + result.activityAdjustmentMl + result.weatherAdjustmentMl + result.userAdjustmentMl} mL',
            ),
            if (result.safetyNotices
                .contains(HydrationFactorCode.fluidRestriction))
              Text(l10n.restrictionSafetyNotice),
          ],
          Text(l10n.generalWellnessNotice),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(
              key: const Key('keep-current-goal'),
              onPressed: () {},
              child: Text(l10n.keepCurrentGoal),
            ),
            if (result == null)
              FilledButton(
                key: const Key('review-suggestion'),
                onPressed: onReview,
                child: Text(l10n.reviewSuggestion),
              )
            else
              FilledButton(
                key: const Key('apply-suggested-goal'),
                onPressed: onApply,
                child: Text(l10n.applySuggestedGoal),
              ),
          ]),
        ]),
      ),
    );
  }
}

String _reproductiveLabel(
  AppLocalizations l10n,
  HydrionReproductiveHydrationState value,
) =>
    switch (value) {
      HydrionReproductiveHydrationState.none => l10n.reproductiveNone,
      HydrionReproductiveHydrationState.pregnant => l10n.reproductivePregnant,
      HydrionReproductiveHydrationState.lactating => l10n.reproductiveLactating,
    };

String _safetyLabel(AppLocalizations l10n, HydrionFluidSafetyMode value) =>
    switch (value) {
      HydrionFluidSafetyMode.none => l10n.fluidSafetyNone,
      HydrionFluidSafetyMode.clinicianTarget => l10n.fluidSafetyClinician,
      HydrionFluidSafetyMode.fluidRestrictionWithoutTarget =>
        l10n.fluidSafetyRestriction,
      HydrionFluidSafetyMode.unsure => l10n.fluidSafetyUnsure,
    };

String _bmiCategoryLabel(
  AppLocalizations l10n,
  HydrionAdultBmiCategory value,
) =>
    switch (value) {
      HydrionAdultBmiCategory.belowStandardRange => l10n.bmiBelowRange,
      HydrionAdultBmiCategory.standardRange => l10n.bmiStandardRange,
      HydrionAdultBmiCategory.aboveStandardRange => l10n.bmiAboveRange,
      HydrionAdultBmiCategory.higherStandardRange => l10n.bmiHigherRange,
    };

String _activityLabel(
  AppLocalizations l10n,
  HydrionActivityIntensity value,
) =>
    switch (value) {
      HydrionActivityIntensity.rest => l10n.activityRest,
      HydrionActivityIntensity.light => l10n.activityLight,
      HydrionActivityIntensity.moderate => l10n.activityModerate,
      HydrionActivityIntensity.vigorous => l10n.activityVigorous,
    };

String _environmentLabel(
  AppLocalizations l10n,
  HydrionEnvironmentExposure value,
) =>
    switch (value) {
      HydrionEnvironmentExposure.mostlyIndoors => l10n.environmentIndoors,
      HydrionEnvironmentExposure.mixed => l10n.environmentMixed,
      HydrionEnvironmentExposure.mostlyOutdoors => l10n.environmentOutdoors,
    };

String _sweatLabel(AppLocalizations l10n, HydrionSweatLevel value) =>
    switch (value) {
      HydrionSweatLevel.low => l10n.sweatLow,
      HydrionSweatLevel.moderate => l10n.sweatModerate,
      HydrionSweatLevel.high => l10n.sweatHigh,
      HydrionSweatLevel.unknown => l10n.sweatUnknown,
    };

String _conditionLabel(
  AppLocalizations l10n,
  HydrionTemporaryCondition value,
) =>
    switch (value) {
      HydrionTemporaryCondition.none => l10n.conditionNone,
      HydrionTemporaryCondition.fever => l10n.conditionFever,
      HydrionTemporaryCondition.vomitingOrDiarrhea =>
        l10n.conditionStomachIllness,
      HydrionTemporaryCondition.recovering => l10n.conditionRecovering,
      HydrionTemporaryCondition.preferNotToSay => l10n.conditionPreferNot,
    };
