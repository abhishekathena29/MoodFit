import 'package:flutter/material.dart';

import '../providers/muse_reply.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/pulsing_dot.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage(this.text, {required this.isUser});
}

/// Muse — the bottom-nav chat tab. Answers fashion/style questions from a
/// small local rule engine ([MuseReply]) and, every few turns, gently folds
/// in a check-in on how the person is actually feeling. Fully on-device —
/// no network call, matching the rest of the app's local-first model.
class MuseScreen extends StatefulWidget {
  const MuseScreen({super.key});

  @override
  State<MuseScreen> createState() => _MuseScreenState();
}

class _MuseScreenState extends State<MuseScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [_ChatMessage(MuseReply.greeting(), isUser: false)];
  int _turnCount = 0;
  bool _typing = false;

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
    setState(() {
      _messages.add(_ChatMessage(text, isUser: true));
      _typing = true;
    });
    _scrollToEnd();

    _turnCount++;
    final reply = MuseReply.reply(text, turnCount: _turnCount);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_ChatMessage(reply, isUser: false));
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
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
                height: 420,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= _messages.length) return const _TypingBubble();
                    return _Bubble(message: _messages[i]);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
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
                      onTap: _send,
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
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;

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
                color: isUser ? AppColors.sage : AppColors.background,
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
              color: AppColors.background,
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
