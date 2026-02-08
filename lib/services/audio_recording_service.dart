import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  bool _isRecording = false;

  Future<void> start({
    required Function(String path) onChunkReady,
  }) async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('Recording permission denied');
      return;
    }

    _isRecording = true;
    _startNewChunk(onChunkReady);

    // 5秒ごとに録音を切り替えてチャンク化
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final path = await _recorder.stop();
        if (path != null) {
          onChunkReady(path);
        }
        if (_isRecording) {
          _startNewChunk(onChunkReady);
        }
      } catch (e) {
        debugPrint('Recording error in loop: $e');
      }
    });
  }

  Future<void> _startNewChunk(Function(String) onChunkReady) async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), 
        path: path
      );
    } catch (e) {
      debugPrint('Start recording chunk error: $e');
    }
  }

  Future<void> stop() async {
    _isRecording = false;
    _timer?.cancel();
    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('Stop recording error: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}