import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/translation_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(translationProvider.notifier).init());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(translationProvider.select((s) => s.items.length), (previous, next) {
      if (next > (previous ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final state = ref.watch(translationProvider);
    final settingsState = ref.watch(settingsProvider);
    final notifier = ref.read(translationProvider.notifier);

    // 音量バーの幅計算 (-2〜10 を 0.0〜1.0 に)
    double level = state.soundLevel;
    if (level < 0) level = 0;
    final double visualWidthFactor = (level / 10.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('おうち留学', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isBluetoothConnected ? Colors.blueAccent.withOpacity(0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    size: 16,
                    color: state.isBluetoothConnected ? Colors.blueAccent : Colors.white24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.isBluetoothConnected ? 'Bluetooth接続中' : 'Bluetooth未接続',
                    style: TextStyle(
                      fontSize: 12,
                      color: state.isBluetoothConnected ? Colors.blueAccent : Colors.white24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), // Spacing between BT and STT status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (() {
                  switch (settingsState.currentSttMode) {
                    case 'cloud': return Colors.green.withOpacity(0.2);
                    case 'onDevice': return Colors.orange.withOpacity(0.2);
                    case 'error': return Colors.red.withOpacity(0.2);
                    default: return Colors.white10;
                  }
                })(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (() {
                      switch (settingsState.currentSttMode) {
                        case 'cloud': return Icons.cloud;
                        case 'onDevice': return Icons.phonelink;
                        case 'error': return Icons.error_outline;
                        default: return Icons.help_outline;
                      }
                    })(),
                    size: 16,
                    color: (() {
                      switch (settingsState.currentSttMode) {
                        case 'cloud': return Colors.greenAccent;
                        case 'onDevice': return Colors.orangeAccent;
                        case 'error': return Colors.redAccent;
                        default: return Colors.white24;
                      }
                    })(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (() {
                      switch (settingsState.currentSttMode) {
                        case 'cloud': return 'クラウド認識';
                        case 'onDevice': return '本体認識';
                        case 'error': return 'エラー';
                        default: return '待機中';
                      }
                    })(),
                    style: TextStyle(
                      fontSize: 12,
                      color: (() {
                        switch (settingsState.currentSttMode) {
                          case 'cloud': return Colors.greenAccent;
                          case 'onDevice': return Colors.orangeAccent;
                          case 'error': return Colors.redAccent;
                          default: return Colors.white24;
                        }
                      })(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () => notifier.clearHistory(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 巨大な音量バー（これでマイクの反応を100%確認できます）
          if (state.isListening)
            Container(
              height: 15,
              width: double.infinity,
              color: Colors.white.withOpacity(0.1),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 15,
                width: MediaQuery.of(context).size.width * visualWidthFactor,
                color: Colors.blueAccent,
              ),
            ),
          Expanded(
            child: state.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tv, size: 80, color: Colors.white10),
                        const SizedBox(height: 32),
                        const Text(
                          'テレビの日本語を待機中...',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.language, size: 12, color: Colors.blueAccent),
                                    SizedBox(width: 4),
                                    Text('日本語', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(item.formattedTime, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(item.originalText, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                            const Divider(height: 24, color: Colors.white10),
                            const Row(
                              children: [
                                Icon(Icons.translate, size: 12, color: Colors.greenAccent),
                                SizedBox(width: 4),
                                Text('ENGLISH', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.translatedText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(state.isListening ? 0.1 : 0),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => notifier.toggleListening(),
              onLongPressStart: (_) => notifier.startHolding(),
              onLongPressEnd: (_) => notifier.stopHolding(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (state.isListening)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 1.4),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCirc,
                          builder: (context, value, child) {
                            return Container(
                              width: 80 * value,
                              height: 80 * value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (state.isListening ? Colors.redAccent : Colors.blueAccent).withOpacity((1.4 - value).clamp(0.0, 1.0)),
                              ),
                            );
                          },
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: state.isListening ? Colors.redAccent : Colors.blueAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (state.isListening ? Colors.redAccent : Colors.blueAccent).withOpacity(0.5),
                              blurRadius: state.isListening ? 20 : 0,
                              spreadRadius: state.isListening ? 5 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          state.isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.isListening ? 'ストップ' : 'おうち留学を開始',
                    style: TextStyle(
                      color: state.isListening ? Colors.redAccent : Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.isListening ? '常時聞き取り中' : 'タップで開始 / 長押しで話す',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}