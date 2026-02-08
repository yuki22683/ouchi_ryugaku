import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'dart:async';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _shouldBeListening = false;
  bool _isRestarting = false;
  Timer? _watchdogTimer; // 監視タイマー

  Future<bool> init() async {
    if (_isAvailable) return true;
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if ((status == 'done' || status == 'notListening') && _shouldBeListening) {
            _restartListening();
          }
        },
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          if (_shouldBeListening) {
            _restartListening();
          }
        },
        finalTimeout: const Duration(milliseconds: 0),
      );
    } catch (e) {
      debugPrint('STT Init Exception: $e');
    }
    return _isAvailable;
  }

  void _restartListening() {
    if (_isRestarting || !_shouldBeListening) return;
    _isRestarting = true;
    
    // 500ms後に再起動
    Future.delayed(const Duration(milliseconds: 500), () {
      _isRestarting = false;
      if (_shouldBeListening) _startListeningInternal();
    });
  }

  void startListening({
    required Function(String words, bool isFinal) onResult,
    required Function(double level) onSoundLevel,
  }) async {
    _shouldBeListening = true;
    _onResultCallback = onResult;
    _onSoundLevelCallback = onSoundLevel;
    
    // 監視タイマー：3秒ごとにチェックし、止まっていたら強制再起動
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_shouldBeListening && !_speech.isListening && !_isRestarting) {
        debugPrint('--- Watchdog: STT is dead. Reviving... ---');
        _startListeningInternal();
      }
    });

    await _startListeningInternal();
  }

  Function(String, bool)? _onResultCallback;
  Function(double)? _onSoundLevelCallback;

  Future<void> _startListeningInternal() async {
    if (!_isAvailable) {
      bool ok = await init();
      if (!ok) return;
    }

    if (_speech.isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty && _onResultCallback != null) {
            _onResultCallback!(result.recognizedWords, result.finalResult);
          }
        },
        onSoundLevelChange: (level) {
          if (_onSoundLevelCallback != null) _onSoundLevelCallback!(level);
        },
        localeId: 'ja-JP',
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 15),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        onDevice: false,
      );
    } catch (e) {
      debugPrint('Listen start failed: $e');
    }
  }

  void stop() {
    _shouldBeListening = false;
    _watchdogTimer?.cancel();
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
