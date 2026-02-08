import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final Ref _ref;
  List<dynamic> _availableVoices = [];

  TtsService(this._ref);

  Future<void> init() async {
    await _flutterTts.setLanguage("en-US"); // Default language for English
    _availableVoices = await _flutterTts.getVoices;
    _applySettings();
  }

  void _applySettings() {
    final settings = _ref.read(settingsProvider);
    _flutterTts.setSpeechRate(settings.speechRate);
    _flutterTts.setVolume(settings.volume);
    _flutterTts.setPitch(1.0); // Pitch remains constant

    if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
      _flutterTts.setVoice({
        "name": settings.selectedVoiceName!,
        "locale": settings.selectedVoiceLocale!,
      });
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    _applySettings(); // Apply latest settings before speaking
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  List<dynamic> get availableVoices => _availableVoices;
}
