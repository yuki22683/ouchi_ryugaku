import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/settings_provider.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _shouldBeListening = false;
  bool _isRestarting = false;
  Timer? _watchdogTimer; // 監視タイマー
  final Ref _ref;

  SpeechService(this._ref);

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
          // If STT fails, try to restart and potentially fallback
          if (_shouldBeListening) {
            _ref.read(settingsProvider.notifier).setCurrentSttMode('error'); // Indicate error state
            _restartListening(forceFallbackCheck: true); // Force a fallback check on restart
          }
        },
        finalTimeout: const Duration(milliseconds: 0),
      );
    } catch (e) {
      debugPrint('STT Init Exception: $e');
    }
    return _isAvailable;
  }

  void _restartListening({bool forceFallbackCheck = false}) {
    if (_isRestarting || !_shouldBeListening) return;
    _isRestarting = true;
    
    // 500ms後に再起動
    Future.delayed(const Duration(milliseconds: 500), () {
      _isRestarting = false;
      if (_shouldBeListening) _startListeningInternal(forceFallbackCheck: forceFallbackCheck);
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
        _restartListening();
      }
    });

    await _startListeningInternal();
  }

  Function(String, bool)? _onResultCallback;
  Function(double)? _onSoundLevelCallback;

  Future<void> _startListeningInternal({bool forceFallbackCheck = false}) async {
    if (!_isAvailable) {
      bool ok = await init();
      if (!ok) return;
    }

    if (_speech.isListening) return;

    final settings = _ref.read(settingsProvider);
    stt.ListenMode currentListenMode = settings.listenMode == 'dictation' ? stt.ListenMode.dictation : stt.ListenMode.confirmation;

    bool useCloud = true; // Default to cloud
    bool triedCloud = false;
    bool triedOnDevice = false;

    // Determine initial mode to try
    if (forceFallbackCheck) {
      // If forced, check connectivity
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        useCloud = false; // No internet, must try onDevice
        debugPrint('No internet, forcing onDevice STT attempt.');
      } else {
        useCloud = true; // Internet available, try cloud STT first
        debugPrint('Internet available, trying cloud STT first.');
      }
    } else {
      // Not forced, follow user's onDevice preference for initial attempt
      useCloud = !settings.enableOnDevice;
    }

    // Attempt to listen with determined mode, with fallback
    while (true) {
      bool success = false;
      String modeUsed = 'unknown';

      if (useCloud && !triedCloud) {
        debugPrint('Attempting Cloud STT...');
        _ref.read(settingsProvider.notifier).setCurrentSttMode('cloud');
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
            listenFor: Duration(seconds: settings.listenForSeconds),
            pauseFor: Duration(seconds: settings.pauseForSeconds),
            listenOptions: stt.SpeechListenOptions(
              partialResults: settings.enablePartialResults,
              listenMode: currentListenMode,
              onDevice: false, // Explicitly cloud
            ),
          );
          success = true;
          modeUsed = 'cloud';
        } catch (e) {
          debugPrint('Cloud STT failed: $e');
          _speech.stop(); // Ensure it's stopped
          triedCloud = true;
        }
      } else if (!useCloud && settings.enableOnDevice && !triedOnDevice) {
        debugPrint('Attempting On-Device STT...');
        _ref.read(settingsProvider.notifier).setCurrentSttMode('onDevice');
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
            listenFor: Duration(seconds: settings.listenForSeconds),
            pauseFor: Duration(seconds: settings.pauseForSeconds),
            listenOptions: stt.SpeechListenOptions(
              partialResults: settings.enablePartialResults,
              listenMode: currentListenMode,
              onDevice: true, // Explicitly onDevice
            ),
          );
          success = true;
          modeUsed = 'onDevice';
        } catch (e) {
          debugPrint('On-Device STT failed: $e');
          _speech.stop(); // Ensure it's stopped
          triedOnDevice = true;
        }
      }

      if (success) {
        _ref.read(settingsProvider.notifier).setCurrentSttMode(modeUsed);
        debugPrint('Successfully started STT in $modeUsed mode.');
        return; // Exit if successful
      } else {
        // If neither was successful or both failed, update status and exit
        if (triedCloud && (!settings.enableOnDevice || triedOnDevice)) {
          _ref.read(settingsProvider.notifier).setCurrentSttMode('failed');
          debugPrint('All STT attempts failed.');
          return;
        }
        // If cloud failed, try onDevice next (if not tried and enabled)
        if (useCloud && triedCloud && settings.enableOnDevice && !triedOnDevice) {
          useCloud = false; // Switch to onDevice
        } else {
          // If onDevice failed, try cloud next (if not tried)
          useCloud = true; // Switch to cloud
          triedCloud = false; // Allow re-trying cloud if onDevice also failed after initial cloud attempt
        }
      }
    }
  }

  void stop() {
    _shouldBeListening = false;
    _watchdogTimer?.cancel();
    _speech.stop();
    _ref.read(settingsProvider.notifier).setCurrentSttMode('unknown'); // Reset mode on stop
  }

  bool get isListening => _speech.isListening;
}
