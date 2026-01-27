import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyana_flutter/core/constants.dart';

part 'settings_provider.freezed.dart';
part 'settings_provider.g.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required String backendUrl,
    required bool toolsEnabled,
    required bool tamilMode,
    required bool isDarkTheme,
    required String geminiModel,
    required bool memoryEnabled,
    required bool mcpEnabled,
    required String responseStyle,
    required String responseTone,
    required int maxOutputTokens,
    @Default('') String customInstructions,
  }) = _SettingsState;
}

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  String _normalizeBackendUrl(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.scheme.isEmpty) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBackendUrl = prefs.getString('backendUrl') ?? AppConstants.defaultBaseUrl;
    final normalizedBackendUrl = _normalizeBackendUrl(storedBackendUrl);
    if (normalizedBackendUrl != storedBackendUrl) {
      await prefs.setString('backendUrl', normalizedBackendUrl);
    }
    return SettingsState(
      backendUrl: normalizedBackendUrl,
      toolsEnabled: prefs.getBool('toolsEnabled') ?? true,
      tamilMode: prefs.getBool('tamilMode') ?? false,
      isDarkTheme: prefs.getBool('isDarkTheme') ?? false,
      geminiModel: prefs.getString('geminiModel') ?? 'deepseek-chat',
      memoryEnabled: prefs.getBool('memoryEnabled') ?? true,
      mcpEnabled: prefs.getBool('mcpEnabled') ?? true,
      responseStyle: prefs.getString('responseStyle') ?? 'Balanced',
      responseTone: prefs.getString('responseTone') ?? 'Friendly',
      maxOutputTokens: prefs.getInt('maxOutputTokens') ?? 350,
      customInstructions: prefs.getString('customInstructions') ?? '',
    );
  }

  Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeBackendUrl(url);
    await prefs.setString('backendUrl', normalized);
    state = AsyncData(state.value!.copyWith(backendUrl: normalized));
  }

  Future<void> toggleTools(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('toolsEnabled', value);
    state = AsyncData(state.value!.copyWith(toolsEnabled: value));
  }
  
  Future<void> toggleTamilMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tamilMode', value);
    state = AsyncData(state.value!.copyWith(tamilMode: value));
  }

  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    state = AsyncData(state.value!.copyWith(isDarkTheme: value));
  }

  Future<void> toggleMemory(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('memoryEnabled', value);
    state = AsyncData(state.value!.copyWith(memoryEnabled: value));
  }

  Future<void> toggleMcp(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mcpEnabled', value);
    state = AsyncData(state.value!.copyWith(mcpEnabled: value));
  }

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiModel', model);
    state = AsyncData(state.value!.copyWith(geminiModel: model));
  }

  Future<void> setCustomInstructions(String instructions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customInstructions', instructions);
    state = AsyncData(state.value!.copyWith(customInstructions: instructions));
  }

  Future<void> setResponseStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('responseStyle', style);
    state = AsyncData(state.value!.copyWith(responseStyle: style));
  }

  Future<void> setResponseTone(String tone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('responseTone', tone);
    state = AsyncData(state.value!.copyWith(responseTone: tone));
  }

  Future<void> setMaxOutputTokens(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxOutputTokens', value);
    state = AsyncData(state.value!.copyWith(maxOutputTokens: value));
  }
}
