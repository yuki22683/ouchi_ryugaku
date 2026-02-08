import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class AudioProcessingService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  bool _isProcessing = false;

  Future<void> start({
    required Function(String path) onChunkReady,
    required Function(double level) onSoundLevel,
  }) async {
    if (_isProcessing) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    _isProcessing = true;
    _startNewChunk(onChunkReady);

    // 5秒ごとに録音を切り替える（これが取りこぼしを防ぐ鍵です）
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final path = await _recorder.stop();
        if (path != null) {
          onChunkReady(path);
        }
        if (_isProcessing) {
          _startNewChunk(onChunkReady);
        }
      } catch (e) {
        debugPrint('Recording cycle error: $e');
      }
    });

    // 音量レベルの監視
    Timer.periodic(const Duration(milliseconds: 100), (t) async {
      if (!_isProcessing) {
        t.cancel();
        return;
      }
      try {
        final amplitude = await _recorder.getAmplitude();
        // dB値を 0-10 程度のスケールに変換
        double level = (amplitude.current + 50).clamp(0, 50) / 5.0;
        onSoundLevel(level);
      } catch (_) {}
    });
  }

  Future<void> _startNewChunk(Function(String) onChunkReady) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        bitRate: 32000,
      ), 
      path: path
    );
  }

  Future<void> stop() async {
    _isProcessing = false;
    _timer?.cancel();
    await _recorder.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}
