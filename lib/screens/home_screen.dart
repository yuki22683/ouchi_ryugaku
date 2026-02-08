import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/translation_provider.dart';

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
    final notifier = ref.read(translationProvider.notifier);

    // 音量バーの幅計算 (-2〜10 を 0.0〜1.0 に)
    double level = state.soundLevel;
    if (level < 0) level = 0;
    final double visualWidthFactor = (level / 10.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('おうち留学', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () => notifier.clearHistory(),
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.formattedTime, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                            const SizedBox(height: 8),
                            Text(item.originalText, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              item.translatedText,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: GestureDetector(
              onTap: () => notifier.toggleListening(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: state.isListening ? Colors.redAccent : Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state.isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.isListening ? 'ストップ' : 'おうち留学を開始',
                    style: TextStyle(color: state.isListening ? Colors.redAccent : Colors.blueAccent, fontWeight: FontWeight.bold),
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