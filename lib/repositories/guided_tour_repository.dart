import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';

class GuidedTourState {
  final String version;
  final bool completed;
  final bool skipped;
  final int currentStep;
  final Set<String> completedContextualTours;
  final Map<String, int> contextualCurrentSteps;
  final bool whatsNewPromptPending;
  final DateTime? lastCoreInteractionAt;

  const GuidedTourState({
    required this.version,
    this.completed = false,
    this.skipped = false,
    this.currentStep = 0,
    this.completedContextualTours = const <String>{},
    this.contextualCurrentSteps = const <String, int>{},
    this.whatsNewPromptPending = false,
    this.lastCoreInteractionAt,
  });

  GuidedTourState copyWith({
    String? version,
    bool? completed,
    bool? skipped,
    int? currentStep,
    Set<String>? completedContextualTours,
    Map<String, int>? contextualCurrentSteps,
    bool? whatsNewPromptPending,
    DateTime? lastCoreInteractionAt,
    bool clearLastCoreInteractionAt = false,
  }) {
    return GuidedTourState(
      version: version ?? this.version,
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      currentStep: currentStep ?? this.currentStep,
      completedContextualTours:
          completedContextualTours ?? this.completedContextualTours,
      contextualCurrentSteps:
          contextualCurrentSteps ?? this.contextualCurrentSteps,
      whatsNewPromptPending:
          whatsNewPromptPending ?? this.whatsNewPromptPending,
      lastCoreInteractionAt: clearLastCoreInteractionAt
          ? null
          : lastCoreInteractionAt ?? this.lastCoreInteractionAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'completed': completed,
        'skipped': skipped,
        'currentStep': currentStep,
        'completedContextualTours': completedContextualTours.toList()..sort(),
        'contextualCurrentSteps': contextualCurrentSteps,
        'whatsNewPromptPending': whatsNewPromptPending,
        'lastCoreInteractionAt': lastCoreInteractionAt?.toIso8601String(),
      };

  static GuidedTourState fromJson(
    Object? value,
    String currentVersion, {
    required bool establishedUser,
    DateTime? now,
  }) {
    GuidedTourState initialState() => GuidedTourState(
          version: currentVersion,
          completed: establishedUser,
          whatsNewPromptPending: establishedUser,
        );
    if (value is! Map) {
      return initialState();
    }
    final version = value['version']?.toString();
    if (version != currentVersion) {
      final contextual = value['completedContextualTours'];
      final rawContextualSteps = value['contextualCurrentSteps'];
      return initialState().copyWith(
        completedContextualTours: contextual is List
            ? contextual
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toSet()
            : const <String>{},
        contextualCurrentSteps: rawContextualSteps is Map
            ? {
                for (final entry in rawContextualSteps.entries)
                  if (entry.value is num)
                    entry.key.toString():
                        (entry.value as num).round().clamp(0, 6).toInt(),
              }
            : const <String, int>{},
      );
    }
    final currentStep = value['currentStep'];
    final contextual = value['completedContextualTours'];
    final rawContextualSteps = value['contextualCurrentSteps'];
    final parsedInteraction = DateTime.tryParse(
      value['lastCoreInteractionAt']?.toString() ?? '',
    );
    final interruptedTooLongAgo = currentStep is num &&
        currentStep.round() > 0 &&
        parsedInteraction != null &&
        (now ?? DateTime.now()).difference(parsedInteraction) >
            const Duration(hours: 24);
    return GuidedTourState(
      version: currentVersion,
      completed: value['completed'] == true,
      skipped: value['skipped'] == true || interruptedTooLongAgo,
      currentStep:
          !interruptedTooLongAgo && currentStep is num && currentStep.isFinite
              ? currentStep.round().clamp(0, 12).toInt()
              : 0,
      completedContextualTours: contextual is List
          ? contextual
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toSet()
          : const <String>{},
      contextualCurrentSteps: rawContextualSteps is Map
          ? {
              for (final entry in rawContextualSteps.entries)
                if (entry.value is num)
                  entry.key.toString():
                      (entry.value as num).round().clamp(0, 6).toInt(),
            }
          : const <String, int>{},
      whatsNewPromptPending: value['whatsNewPromptPending'] == true,
      lastCoreInteractionAt: interruptedTooLongAgo ? null : parsedInteraction,
    );
  }
}

class GuidedTourRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.guided_tour.v1';
  static const currentVersion = 'release18-polished-tour-v2';
  static const release18ContextualTourIds = <String>{
    'bottle-bingo:release18-v1',
    'pomodoro-sip:release18-v1',
    'temperature-roulette:release18-v1',
    'around-the-world-infusion-week:release18-v1',
  };

  final HydrionLocalStore _store;
  GuidedTourState _state;
  bool _replayRequested = false;
  final Set<String> _contextualReplayRequests = <String>{};

  GuidedTourRepository._(this._store, this._state);

  GuidedTourRepository.memory({
    bool completed = true,
    bool contextualToursCompleted = true,
    bool whatsNewPromptPending = false,
  }) : this._(
          MemoryHydrionStore(),
          GuidedTourState(
            version: currentVersion,
            completed: completed,
            whatsNewPromptPending: whatsNewPromptPending,
            completedContextualTours: contextualToursCompleted
                ? release18ContextualTourIds
                : const <String>{},
          ),
        );

  static Future<GuidedTourRepository> load(
    HydrionLocalStore store, {
    bool establishedUser = false,
    DateTime? now,
  }) async {
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
      GuidedTourState.fromJson(
        decoded,
        currentVersion,
        establishedUser: establishedUser,
        now: now,
      ),
    );
  }

  GuidedTourState get state => _state;

  bool get shouldShowCoreTour =>
      _replayRequested || (!_state.completed && !_state.skipped);

  bool get shouldOfferWhatsNew =>
      _state.whatsNewPromptPending && !_replayRequested;

  int get currentStep => _state.currentStep;

  Future<void> setCurrentStep(int step) async {
    _state = _state.copyWith(
      currentStep: step.clamp(0, 12).toInt(),
      lastCoreInteractionAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> completeCoreTour() async {
    _replayRequested = false;
    _state = _state.copyWith(
      completed: true,
      skipped: false,
      currentStep: 0,
      whatsNewPromptPending: false,
      clearLastCoreInteractionAt: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> skipCoreTour() async {
    _replayRequested = false;
    _state = _state.copyWith(
      skipped: true,
      currentStep: 0,
      whatsNewPromptPending: false,
      clearLastCoreInteractionAt: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> replayCoreTour() async {
    _replayRequested = true;
    _state = _state.copyWith(
      currentStep: 0,
      lastCoreInteractionAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> showWhatsNewTour() async {
    _replayRequested = true;
    _state = _state.copyWith(
      currentStep: 0,
      whatsNewPromptPending: false,
      lastCoreInteractionAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> dismissWhatsNew() async {
    _state = _state.copyWith(whatsNewPromptPending: false);
    await _persist();
    notifyListeners();
  }

  bool isContextualTourComplete(String id) =>
      _state.completedContextualTours.contains(id);

  bool shouldShowContextualTour(String id) =>
      id.trim().isNotEmpty &&
      (_contextualReplayRequests.contains(id) ||
          !_state.completedContextualTours.contains(id));

  int contextualCurrentStep(String id) =>
      _state.contextualCurrentSteps[id] ?? 0;

  Future<void> setContextualCurrentStep(String id, int step) async {
    if (id.trim().isEmpty) return;
    _state = _state.copyWith(
      contextualCurrentSteps: {
        ..._state.contextualCurrentSteps,
        id: step.clamp(0, 6).toInt(),
      },
    );
    await _persist();
    notifyListeners();
  }

  Future<void> completeContextualTour(String id) async {
    if (id.trim().isEmpty) return;
    _contextualReplayRequests.remove(id);
    final nextSteps = <String, int>{..._state.contextualCurrentSteps}
      ..remove(id);
    _state = _state.copyWith(
      completedContextualTours: {
        ..._state.completedContextualTours,
        id,
      },
      contextualCurrentSteps: nextSteps,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> skipContextualTour(String id) => completeContextualTour(id);

  void replayContextualTour(String id) {
    if (id.trim().isEmpty) return;
    _contextualReplayRequests.add(id);
    _state = _state.copyWith(
      contextualCurrentSteps: {
        ..._state.contextualCurrentSteps,
        id: 0,
      },
    );
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.writeString(storageKey, jsonEncode(_state.toJson()));
  }
}
