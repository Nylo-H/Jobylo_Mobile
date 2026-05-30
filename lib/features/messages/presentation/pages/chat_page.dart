import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../../shared/widgets/avatar_with_badge.dart';
import '../providers/messages_provider.dart';
import '../../domain/entities/message.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUsername;
  final String? otherUserId;
  final String? jobId;
  final String? jobTitle;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUsername,
    this.otherUserId,
    this.jobId,
    this.jobTitle,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    _isAtBottom = pos.pixels >= pos.maxScrollExtent - 80;
    if (pos.pixels <= 120) {
      ref.read(chatProvider(widget.conversationId).notifier).loadMore();
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (animate) {
        _scrollCtrl.animateTo(max,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        _scrollCtrl.jumpTo(max);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    _inputCtrl.clear();
    setState(() => _isSending = true);
    try {
      await ref.read(chatProvider(widget.conversationId).notifier).send(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.conversationId));

    ref.listen(chatProvider(widget.conversationId), (prev, next) {
      next.whenData((cs) {
        final prevLen = prev?.valueOrNull?.messages.length ?? 0;
        if (cs.messages.length > prevLen && _isAtBottom) _scrollToBottom();
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F8),
      appBar: _ChatAppBar(
        username: widget.otherUsername,
        otherUserId: widget.otherUserId,
      ),
      body: Column(
        children: [
          // ── Bandeau job cliquable ───────────────────────────────────
          if (widget.jobId != null && widget.jobId!.isNotEmpty)
            _JobBanner(
              jobId: widget.jobId!,
              jobTitle: widget.jobTitle ?? 'Voir l\'annonce',
            ),

          // ── Messages ────────────────────────────────────────────────
          Expanded(
            child: chatAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppError(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(chatProvider(widget.conversationId)),
              ),
              data: (chatState) {
                final msgs = chatState.messages;
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(chatProvider(widget.conversationId)),
                  child: msgs.isEmpty
                      ? const _EmptyChat()
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(
                                  AppSizes.md, AppSizes.sm,
                                  AppSizes.md, AppSizes.sm),
                              itemCount: msgs.length,
                              itemBuilder: (ctx, i) {
                                final msg = msgs[i];
                                final prev = i > 0 ? msgs[i - 1] : null;
                                final showDate = prev == null ||
                                    !_sameDay(
                                        prev.timestamp, msg.timestamp);
                                return Column(
                                  children: [
                                    if (showDate)
                                      _DateDivider(date: msg.timestamp),
                                    _MessageBubble(
                                      message: msg,
                                      isMe: msg.senderId !=
                                          widget.otherUserId,
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (chatState.isLoadingMore)
                              const Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(
                                    minHeight: 2,
                                    color: AppColors.primary),
                              ),
                          ],
                        ),
                );
              },
            ),
          ),

          // ── Input ───────────────────────────────────────────────────
          _InputBar(
            controller: _inputCtrl,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Job banner ────────────────────────────────────────────────────────────
class _JobBanner extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  const _JobBanner({required this.jobId, required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/jobs/$jobId'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          border: const Border(
            bottom: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(Icons.work_outline,
                  size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Annonce concernée',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    jobTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── App bar with presence ─────────────────────────────────────────────────
class _ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String username;
  final String? otherUserId;

  const _ChatAppBar({required this.username, this.otherUserId});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = otherUserId != null
        ? (ref.watch(presenceProvider(otherUserId!)).valueOrNull ?? false)
        : false;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          AvatarWithBadge(name: username, size: 38, showOnline: isOnline),
          const SizedBox(width: AppSizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isOnline ? 'En ligne' : 'Hors ligne',
                  key: ValueKey(isOnline),
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? AppColors.online : AppColors.offline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(children: [
            Icon(Icons.chat_bubble_outline,
                size: 56, color: AppColors.textHint),
            SizedBox(height: AppSizes.md),
            Text('Commencez la conversation...',
                style: TextStyle(fontSize: 14, color: AppColors.textHint)),
          ]),
        ),
      ],
    );
  }
}

// ── Date divider ──────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime? date;
  const _DateDivider({this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          child: Text(_format(date),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }

  String _format(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return "Aujourd'hui";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Hier';
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ── Message bubble ────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 3,
        bottom: 3,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56,
      ),
      child: Align(
        alignment:
            isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft:
                      const Radius.circular(AppSizes.radiusMd),
                  topRight:
                      const Radius.circular(AppSizes.radiusMd),
                  bottomLeft: Radius.circular(
                      isMe ? AppSizes.radiusMd : 4),
                  bottomRight: Radius.circular(
                      isMe ? 4 : AppSizes.radiusMd),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.formattedTime,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add,
                    color: AppColors.textSecondary, size: 20),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Écrivez votre message...',
                  hintStyle: const TextStyle(
                      color: AppColors.textHint, fontSize: 15),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                    : const Icon(Icons.send,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
