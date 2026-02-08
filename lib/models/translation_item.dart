import 'package:intl/intl.dart';

class TranslationItem {
  final String id;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;

  TranslationItem({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
  });

  String get formattedTime => DateFormat('HH:mm:ss').format(timestamp);
}
