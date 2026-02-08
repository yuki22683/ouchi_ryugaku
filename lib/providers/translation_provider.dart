import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/translation_item.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

final speechServiceProvider = Provider((ref) => SpeechService());
final translationServiceProvider = Provider((ref) => TranslationService());
final ttsServiceProvider = Provider((ref) => TtsService());

class TranslationState {
  final List<TranslationItem> items;
  final bool isListening;
  final bool isServiceInitialized;
  final double soundLevel;

  TranslationState({
    this.items = const [],
    this.isListening = false,
    this.isServiceInitialized = false,
    this.soundLevel = 0,
  });

  TranslationState copyWith({
    List<TranslationItem>? items,
    bool? isListening,
    bool? isServiceInitialized,
    double? soundLevel,
  }) {
    return TranslationState(
      items: items ?? this.items,
      isListening: isListening ?? this.isListening,
      isServiceInitialized: isServiceInitialized ?? this.isServiceInitialized,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  final SpeechService _speechService;
  final TranslationService _translationService;
  final TtsService _ttsService;
  final _uuid = const Uuid();

  TranslationNotifier(
    this._speechService,
    this._translationService,
    this._ttsService,
  ) : super(TranslationState());

  Future<void> init() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    await _ttsService.init();
    final ok = await _speechService.init();
    state = state.copyWith(isServiceInitialized: ok);
  }

  String _lastWords = '';

  void toggleListening() {
    if (state.isListening) {
      _speechService.stop();
      state = state.copyWith(isListening: false, soundLevel: 0);
    } else {
      state = state.copyWith(isListening: true);
      _speechService.startListening(
        onSoundLevel: (level) {
          state = state.copyWith(soundLevel: level);
        },
        onResult: (words, isFinal) async {
          if (!isFinal || words.isEmpty) return;
          if (words == _lastWords) return;
          
          _lastWords = words;

          final translated = await _translationService.translate(words);
          final newItem = TranslationItem(
            id: _uuid.v4(),
            originalText: words,
            translatedText: translated,
            timestamp: DateTime.now(),
          );
          
          state = state.copyWith(
            items: [...state.items, newItem],
          );
          
          await _ttsService.speak(translated);
        },
      );
    }
  }

  void clearHistory() {
    state = state.copyWith(items: []);
  }
}

final translationProvider = StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier(
    ref.watch(speechServiceProvider),
    ref.watch(translationServiceProvider),
    ref.watch(ttsServiceProvider),
  );
});