import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  Future<String> translate(String text) async {
    if (text.isEmpty) return '';
    try {
      // 入力テキストがアルファベットのみ（ローマ字）の場合でも
      // 「日本語から英語へ」という方向を明示することで
      // 翻訳エンジン側で「日本語の音」として再解釈させます。
      var translation = await _translator.translate(
        text, 
        from: 'ja', 
        to: 'en'
      );
      return translation.text;
    } catch (e) {
      return 'Translation Error: $e';
    }
  }
}