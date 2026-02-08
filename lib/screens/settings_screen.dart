import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/translation_provider.dart'; // For ttsServiceProvider

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final ttsService = ref.read(ttsServiceProvider); // Get TtsService to access available voices

    // Filter for English voices (en-US, en-GB, etc.)
    final List<dynamic> englishVoices = ttsService.availableVoices
        .where((voice) {
          final locale = voice['locale'] as String;
          return locale.startsWith('en-');
        })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('設定', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('音声出力 (Text-to-Speech)'),
          _buildSettingSection(
            context,
            title: '音量',
            value: (settings.volume * 100).round().toString(),
            slider: Slider(
              value: settings.volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: (settings.volume * 100).round().toString(),
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white24,
              onChanged: (newValue) {
                notifier.setVolume(newValue);
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            context,
            title: '速度',
            value: (settings.speechRate * 100).round().toString(),
            slider: Slider(
              value: settings.speechRate,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: (settings.speechRate * 100).round().toString(),
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white24,
              onChanged: (newValue) {
                notifier.setSpeechRate(newValue);
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildVoiceSelectionSection(
            context,
            englishVoices: englishVoices,
            selectedVoiceName: settings.selectedVoiceName,
            selectedVoiceLocale: settings.selectedVoiceLocale,
            onChanged: (String? name, String? locale) {
              notifier.setSelectedVoice(name, locale);
            },
          ),

          const SizedBox(height: 32),
          _buildSectionTitle('音声認識 (Speech-to-Text)'),
          _buildSettingSection(
            context,
            title: '最大認識時間 (秒)',
            value: settings.listenForSeconds.toString(),
            slider: Slider(
              value: settings.listenForSeconds.toDouble(),
              min: 1.0,
              max: 600.0, // Max 10 minutes
              divisions: 600,
              label: settings.listenForSeconds.toString(),
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white24,
              onChanged: (newValue) {
                notifier.setListenForSeconds(newValue.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            context,
            title: '無音で一時停止する時間 (秒)',
            value: settings.pauseForSeconds.toString(),
            slider: Slider(
              value: settings.pauseForSeconds.toDouble(),
              min: 1.0,
              max: 60.0, // Max 60 seconds
              divisions: 60,
              label: settings.pauseForSeconds.toString(),
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white24,
              onChanged: (newValue) {
                notifier.setPauseForSeconds(newValue.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchSetting(
            context,
            title: '部分的な認識結果を有効にする',
            subtitle: 'これをオンにすると、認識途中のテキストも提供されます。（通常は最終結果のみ処理されます）',
            value: settings.enablePartialResults,
            onChanged: (newValue) {
              notifier.setEnablePartialResults(newValue);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchSetting(
            context,
            title: 'オンデバイス認識を有効にする',
            subtitle: 'インターネット接続なしで認識を試みます。（精度が低い場合があります）',
            value: settings.enableOnDevice,
            onChanged: (newValue) {
              notifier.setEnableOnDevice(newValue);
            },
          ),
          const SizedBox(height: 16),
          _buildListenModeSelection(
            context,
            currentMode: settings.listenMode,
            onChanged: (newValue) {
              if (newValue != null) {
                notifier.setListenMode(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingSection(BuildContext context, {
    required String title,
    required String value,
    required Widget slider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          slider,
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelectionSection(
    BuildContext context, {
    required List<dynamic> englishVoices,
    String? selectedVoiceName,
    String? selectedVoiceLocale,
    required Function(String?, String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '英語話者の選択',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedVoiceName,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white70,
            hint: const Text('デフォルト', style: TextStyle(color: Colors.white54)),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('デフォルト', style: TextStyle(color: Colors.white)),
              ),
              ...englishVoices.map<DropdownMenuItem<String>>((voice) {
                final voiceName = voice['name'] as String;
                final voiceLocale = voice['locale'] as String;
                return DropdownMenuItem<String>(
                  value: voiceName,
                  child: Text('$voiceName ($voiceLocale)', style: const TextStyle(color: Colors.white)),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) {
                onChanged(null, null);
              } else {
                final selected = englishVoices.firstWhere((voice) => voice['name'] == value);
                onChanged(selected['name'] as String, selected['locale'] as String);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListenModeSelection(BuildContext context, {
    required String currentMode,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '認識モード',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              RadioListTile<String>(
                title: const Text('Dictation (通常モード)', style: TextStyle(color: Colors.white)),
                value: 'dictation',
                groupValue: currentMode,
                onChanged: onChanged,
                activeColor: Colors.blueAccent,
              ),
              RadioListTile<String>(
                title: const Text('Confirmation (短いフレーズ向け)', style: TextStyle(color: Colors.white)),
                value: 'confirmation',
                groupValue: currentMode,
                onChanged: onChanged,
                activeColor: Colors.blueAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
