import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';

class GuidedTourState {
  final String version;
  final bool completed;
  final bool skipped;
  final int currentStep;
  final Set<String> completedContextualTours;

  const GuidedTourState({
    required this.version,
    this.completed = false,
    this.skipped = false,
    this.currentStep = 0,
    this.completedContextualTours = const <String>{},
  });

  GuidedTourState copyWith({
    String? version,
    bool? completed,
    bool? skipped,
    int? currentStep,
    Set<String>? completedContextualTours,
  }) {
    return GuidedTourState(
      version: version ?? this.version,
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      currentStep: currentStep ?? this.currentStep,
      completedContextualTours:
          completedContextualTours ?? this.completedContextualTours,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'completed': completed,
        'skipped': skipped,
        'currentStep': currentStep,
        'completedContextualTours': completedContextualTours.toList()..sort(),
      };

  static GuidedTourState fromJson(Object? value, String currentVersion) {
    if (value is! Map) {
      return GuidedTourState(version: currentVersion);
    }
    final version = value['version']?.toString();
    if (version != currentVersion) {
      return GuidedTourState(version: currentVersion);
    }
    final currentStep = value['currentStep'];
    final contextual = value['completedContextualTours'];
    return GuidedTourState(
      version: currentVersion,
      completed: value['completed'] == true,
      skipped: value['skipped'] == true,
      currentStep: currentStep is num && currentStep.isFinite
          ? currentStep.round().clamp(0, 12).toInt()
          : 0,
      completedContextualTours: contextual is List
          ? contextual
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toSet()
          : const <String>{},
    );
  }
}

class GuidedTourRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.guided_tour.v1';
  static const currentVersion = 'release18-core-tour';

  final HydrionLocalStore _store;
  GuidedTourState _state;
  bool _replayRequested = false;

  GuidedTourRepository._(this._store, this._state);

  GuidedTourRepository.memory({bool completed = true})
      : this._(
          MemoryHydrionStore(),
          GuidedTourState(version: currentVersion, completed: completed),
        );

  static Future<GuidedTourRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    Object? decoded;
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        decoded = null;
      }
    }
    return GuidedTourRepository._(
      store,
      GuidedTourState.fromJson(decoded, currentVersion),
    );
  }

  GuidedTourState get state => _state;

  bool get shouldShowCoreTour =>
      _replayRequested || (!_state.completed && !_state.skipped);

  int get currentStep => _state.currentStep;

  Future<void> setCurrentStep(int step) async {
    _state = _state.copyWith(currentStep: step.clamp(0, 12).toInt());
    await _persist();
    notifyListeners();
  }

  Future<void> completeCoreTour() async {
    _replayRequested = false;
    _state = _state.copyWith(completed: true, skipped: false, currentStep: 0);
    await _persist();
    notifyListeners();
  }

  Future<void> skipCoreTour() async {
    _replayRequested = false;
    _state = _state.copyWith(skipped: true, currentStep: 0);
    await _persist();
    notifyListeners();
  }

  void replayCoreTour() {
    _replayRequested = true;
    _state = _state.copyWith(currentStep: 0);
    notifyListeners();
  }

  bool isContextualTourComplete(String id) =>
      _state.completedContextualTours.contains(id);

  Future<void> completeContextualTour(String id) async {
    if (id.trim().isEmpty) return;
    _state = _state.copyWith(
      completedContextualTours: {
        ..._state.completedContextualTours,
        id,
      },
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.writeString(storageKey, jsonEncode(_state.toJson()));
  }
}
