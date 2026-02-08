import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'dart:async';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _shouldBeListening = false;
  bool _isRestarting = false;

  Future<bool> init() async {
    if (_isAvailable) return true;
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if ((status == 'done' || status == 'notListening') && _shouldBeListening && !_isRestarting) {
            _restartListening();
          }
        },
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          if (_shouldBeListening && !_isRestarting) {
            _restartListening();
          }
        },
      );
    } catch (e) {
      debugPrint('STT Init Exception: $e');
    }
    return _isAvailable;
  }

  void _restartListening() {
    _isRestarting = true;
    // error_client 回避のため500ms待機
    Future.delayed(const Duration(milliseconds: 500), () {
      _isRestarting = false;
      if (_shouldBeListening) _startListeningInternal();
    });
  }

  Function(String)? _onResultCallback;
  Function(double)? _onSoundLevelCallback;

  void startListening({
    required Function(String words) onResult,
    required Function(double level) onSoundLevel,
  }) async {
    _shouldBeListening = true;
    _onResultCallback = onResult;
    _onSoundLevelCallback = onSoundLevel;
    await _startListeningInternal();
  }

  Future<void> _startListeningInternal() async {
    if (!_isAvailable) await init();
    if (_speech.isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty && _onResultCallback != null) {
            _onResultCallback!(result.recognizedWords);
          }
        },
        onSoundLevelChange: (level) {
          if (_onSoundLevelCallback != null) _onSoundLevelCallback!(level);
        },
        localeId: 'ja-JP', // ハイフン形式で固定
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 15),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        onDevice: false, 
      );
    } catch (e) {
      debugPrint('Listen call failed: $e');
    }
  }

  void stop() {
    _shouldBeListening = false;
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
