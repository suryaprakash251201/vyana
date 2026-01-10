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
    @Default('') String customInstructions,
  }) = _SettingsState;
}

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      backendUrl: prefs.getString('backendUrl') ?? AppConstants.defaultBaseUrl,
      toolsEnabled: prefs.getBool('toolsEnabled') ?? true,
      tamilMode: prefs.getBool('tamilMode') ?? false,
      isDarkTheme: prefs.getBool('isDarkTheme') ?? false,
      geminiModel: prefs.getString('geminiModel') ?? 'llama-3.1-8b-instant',
      memoryEnabled: prefs.getBool('memoryEnabled') ?? true,
      mcpEnabled: prefs.getBool('mcpEnabled') ?? true,
      customInstructions: prefs.getString('customInstructions') ?? '',
    );
  }

  Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backendUrl', url);
    state = AsyncData(state.value!.copyWith(backendUrl: url));
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
}
