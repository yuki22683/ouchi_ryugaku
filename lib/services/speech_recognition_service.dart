import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SpeechRecognitionService {
  // 開発者の方はここに OpenAI の API キーを入力してください
  static const String _apiKey = 'YOUR_OPENAI_API_KEY';

  Future<String> transcribe(String filePath) async {
    if (_apiKey == 'YOUR_OPENAI_API_KEY') {
      return '[APIキー未設定] 録音ファイル: ${filePath.split('/').last}';
    }

    final url = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'ja'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['text'];
      } else {
        debugPrint('Whisper Error: $responseBody');
        return 'Transcription Error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Whisper Exception: $e');
      return 'Transcription Exception: $e';
    } finally {
      // ファイルを削除してクリーンアップ
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
