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

final lowCostSettingsProvider = AsyncNotifierProvider<LowCostSettingsNotifier, LowCostSettingsState>(
  LowCostSettingsNotifier.new,
);

class LowCostSettingsNotifier extends AsyncNotifier<LowCostSettingsState> {

  static const _keyEnabled = 'lowCostEnabled';
  static const _keyMaxChars = 'lowCostMaxChars';
  static const _keyFallbackModel = 'lowCostFallbackModel';
  static const _validModels = ['deepseek-chat', 'deepseek-reasoner'];
  static const _defaultModel = 'deepseek-chat';

  @override
  Future<LowCostSettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    final maxChars = prefs.getInt(_keyMaxChars) ?? 1200;
    var fallbackModel = prefs.getString(_keyFallbackModel) ?? _defaultModel;
    
    // Migrate old models to DeepSeek
    if (!_validModels.contains(fallbackModel)) {
      fallbackModel = _defaultModel;
      await prefs.setString(_keyFallbackModel, fallbackModel);
    }
    
    return LowCostSettingsState(
      enabled: enabled,
      maxInputChars: maxChars,
      fallbackModel: fallbackModel,
    );
  }

  Future<void> setEnabled(bool value) async {
    final current = state.value ?? const LowCostSettingsState(enabled: true, maxInputChars: 1200, fallbackModel: _defaultModel);
    state = AsyncValue.data(current.copyWith(enabled: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  Future<void> setMaxInputChars(int value) async {
    final normalized = value.clamp(200, 4000);
    final current = state.value ?? const LowCostSettingsState(enabled: true, maxInputChars: 1200, fallbackModel: _defaultModel);
    state = AsyncValue.data(current.copyWith(maxInputChars: normalized));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxChars, normalized);
  }

  Future<void> setFallbackModel(String value) async {
    final current = state.value ?? const LowCostSettingsState(enabled: true, maxInputChars: 1200, fallbackModel: _defaultModel);
    state = AsyncValue.data(current.copyWith(fallbackModel: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFallbackModel, value);
  }
}
