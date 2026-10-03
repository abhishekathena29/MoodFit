import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/user_data_provider.dart';
import '../providers/muse_provider.dart';
import '../providers/muse_reply.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/pulsing_dot.dart';

/// Muse — the bottom-nav chat tab. Replies come from Groq via
/// [MuseProvider] (falling back to the local [MuseReply] rules), and the
/// conversation is saved to Firestore so it survives restarts.
class MuseScreen extends StatefulWidget {
  const MuseScreen({super.key});

  @override
  State<MuseScreen> createState() => _MuseScreenState();
}

class _MuseScreenState extends State<MuseScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _lastCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _scrollToEnd();
    await context.read<MuseProvider>().send(text, context.read<UserDataProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final muse = context.watch<MuseProvider>();
    final name = context.select<UserDataProvider, String>((s) => s.name);
    final messages = [
      MuseMessage(id: 'greeting', text: MuseReply.greeting(name), isUser: false),
      ...muse.messages,
    ];
    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      _scrollToEnd();
    }
    // Screen height minus the shared header/xp bar, Muse's own title block,
    // the input row and the floating bottom nav's clearance — so the input
    // stays visible above the nav instead of scrolling behind it.
    final chatHeight = (MediaQuery.sizeOf(context).height - 450).clamp(320.0, 620.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('MUSE', style: AppTheme.mono()),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    'Style & check-ins',
                    style: AppTheme.sans(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.sage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ask about outfits, palettes or style.',
              style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: chatHeight,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length + (muse.typing ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= messages.length) return const _TypingBubble();
                  return _Bubble(message: messages[i]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _controller,
                      style: AppTheme.sans(fontSize: 14),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'What should I wear today?',
                        hintStyle: AppTheme.sans(fontSize: 14, color: AppColors.foreground.withValues(alpha: 0.35)),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.foreground,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: muse.typing ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Icon(Icons.arrow_upward_rounded, size: 18, color: AppColors.background),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MuseMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.sage : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: AppTheme.sans(
                  fontSize: 13,
                  height: 1.5,
                  color: isUser ? Colors.white : AppColors.foreground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: PulsingDot(color: AppColors.foreground.withValues(alpha: 0.4), size: 6),
          ),
        ],
      ),
    );
  }
}
