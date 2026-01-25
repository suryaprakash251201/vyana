import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LowCostSettingsState {
  final bool enabled;
  final int maxInputChars;
  final String fallbackModel;

  const LowCostSettingsState({
    required this.enabled,
    required this.maxInputChars,
    required this.fallbackModel,
  });

  LowCostSettingsState copyWith({
    bool? enabled,
    int? maxInputChars,
    String? fallbackModel,
  }) {
    return LowCostSettingsState(
      enabled: enabled ?? this.enabled,
      maxInputChars: maxInputChars ?? this.maxInputChars,
      fallbackModel: fallbackModel ?? this.fallbackModel,
    );
  }
}

final lowCostSettingsProvider = StateNotifierProvider<LowCostSettingsNotifier, AsyncValue<LowCostSettingsState>>(
  (ref) => LowCostSettingsNotifier(),
);

class LowCostSettingsNotifier extends StateNotifier<AsyncValue<LowCostSettingsState>> {
  LowCostSettingsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  static const _keyEnabled = 'lowCostEnabled';
  static const _keyMaxChars = 'lowCostMaxChars';
  static const _keyFallbackModel = 'lowCostFallbackModel';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyEnabled) ?? true;
      final maxChars = prefs.getInt(_keyMaxChars) ?? 1200;
      final fallbackModel = prefs.getString(_keyFallbackModel) ?? 'llama-3.1-8b-instant';
      state = AsyncValue.data(
        LowCostSettingsState(
          enabled: enabled,
          maxInputChars: maxChars,
          fallbackModel: fallbackModel,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setEnabled(bool value) async {
    final current = state.valueOrNull ?? const LowCostSettingsState(enabled: true, maxInputChars: 1200, fallbackModel: 'llama-3.1-8b-instant');
    state = AsyncValue.data(current.copyWith(enabled: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  Future<void> setMaxInputChars(int value) async {
    final normalized = value.clamp(200, 4000);
    final current = state.valueOrNull ?? const LowCostSettingsState(enabled: true, maxInputChars: 1200, fallbackModel: 'llama-3.1-8b-instant');
    state = AsyncValue.data(current.copyWith(maxInputChars: normalized));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxChars, normalized);
  }

  Future<void> setFallbackModel(String value) async {
    final current = state.valueOrNull ?? const LowCostSettingsState(enabled: true, maxInputChars: 1200, fallbackModel: 'llama-3.1-8b-instant');
    state = AsyncValue.data(current.copyWith(fallbackModel: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFallbackModel, value);
  }
}
