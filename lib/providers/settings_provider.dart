import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final double volume;
  final double speechRate;
  final String? selectedVoiceName;
  final String? selectedVoiceLocale;

  // Speech-to-Text settings
  final int listenForSeconds;
  final int pauseForSeconds;
  final bool enablePartialResults;
  final bool enableOnDevice; // This is the user's preference for on-device
  final String listenMode; // 'dictation' or 'confirmation'
  final String currentSttMode; // 'cloud', 'onDevice', or 'unknown'

  SettingsState({
    this.volume = 1.0,
    this.speechRate = 0.5,
    this.selectedVoiceName,
    this.selectedVoiceLocale,
    this.listenForSeconds = 300, // 5 minutes
    this.pauseForSeconds = 15,
    this.enablePartialResults = true,
    this.enableOnDevice = false,
    this.listenMode = 'dictation',
    this.currentSttMode = 'unknown',
  });

  SettingsState copyWith({
    double? volume,
    double? speechRate,
    String? selectedVoiceName,
    String? selectedVoiceLocale,
    int? listenForSeconds,
    int? pauseForSeconds,
    bool? enablePartialResults,
    bool? enableOnDevice,
    String? listenMode,
    String? currentSttMode,
  }) {
    return SettingsState(
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      selectedVoiceName: selectedVoiceName, // Can be null for clear selection
      selectedVoiceLocale: selectedVoiceLocale, // Can be null for clear selection
      listenForSeconds: listenForSeconds ?? this.listenForSeconds,
      pauseForSeconds: pauseForSeconds ?? this.pauseForSeconds,
      enablePartialResults: enablePartialResults ?? this.enablePartialResults,
      enableOnDevice: enableOnDevice ?? this.enableOnDevice,
      listenMode: listenMode ?? this.listenMode,
      currentSttMode: currentSttMode ?? this.currentSttMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  static const _keyVolume = 'tts_volume';
  static const _keyRate = 'tts_rate';
  static const _keySelectedVoiceName = 'tts_selected_voice_name';
  static const _keySelectedVoiceLocale = 'tts_selected_voice_locale';

  static const _keyListenForSeconds = 'stt_listen_for_seconds';
  static const _keyPauseForSeconds = 'stt_pause_for_seconds';
  static const _keyEnablePartialResults = 'stt_enable_partial_results';
  static const _keyEnableOnDevice = 'stt_enable_on_device';
  static const _keyListenMode = 'stt_listen_mode';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      volume: prefs.getDouble(_keyVolume) ?? 1.0,
      speechRate: prefs.getDouble(_keyRate) ?? 0.5,
      selectedVoiceName: prefs.getString(_keySelectedVoiceName),
      selectedVoiceLocale: prefs.getString(_keySelectedVoiceLocale),
      listenForSeconds: prefs.getInt(_keyListenForSeconds) ?? 300,
      pauseForSeconds: prefs.getInt(_keyPauseForSeconds) ?? 15,
      enablePartialResults: prefs.getBool(_keyEnablePartialResults) ?? true,
      enableOnDevice: prefs.getBool(_keyEnableOnDevice) ?? false,
      listenMode: prefs.getString(_keyListenMode) ?? 'dictation',
    );
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, volume);
  }

  Future<void> setSpeechRate(double rate) async {
    state = state.copyWith(speechRate: rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRate, rate);
  }

  Future<void> setSelectedVoice(String? name, String? locale) async {
    state = state.copyWith(selectedVoiceName: name, selectedVoiceLocale: locale);
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString(_keySelectedVoiceName, name);
    } else {
      await prefs.remove(_keySelectedVoiceName);
    }
    if (locale != null) {
      await prefs.setString(_keySelectedVoiceLocale, locale);
    } else {
      await prefs.remove(_keySelectedVoiceLocale);
    }
  }

  Future<void> setListenForSeconds(int seconds) async {
    state = state.copyWith(listenForSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyListenForSeconds, seconds);
  }

  Future<void> setPauseForSeconds(int seconds) async {
    state = state.copyWith(pauseForSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPauseForSeconds, seconds);
  }

  Future<void> setEnablePartialResults(bool enable) async {
    state = state.copyWith(enablePartialResults: enable);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnablePartialResults, enable);
  }

  Future<void> setEnableOnDevice(bool enable) async {
    state = state.copyWith(enableOnDevice: enable);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableOnDevice, enable);
  }

  Future<void> setListenMode(String mode) async {
    state = state.copyWith(listenMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyListenMode, mode);
  }

  void setCurrentSttMode(String mode) {
    state = state.copyWith(currentSttMode: mode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
