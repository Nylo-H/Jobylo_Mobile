import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../../shared/widgets/app_empty.dart';
import '../../../../shared/widgets/avatar_with_badge.dart';
import '../../domain/entities/conversation.dart';
import '../providers/messages_provider.dart';
import 'chat_page.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              tooltip: 'Actualiser',
              onPressed: () =>
                  ref.read(conversationsProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barre de recherche ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.sm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textHint, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.textHint),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Liste conversations ─────────────────────────────────────
          Expanded(
            child: conversationsAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppError(
                message: e.toString(),
                onRetry: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
              ),
              data: (conversations) {
                final filtered = _query.isEmpty
                    ? conversations
                    : conversations
                        .where((c) =>
                            c.otherUserUsername
                                .toLowerCase()
                                .contains(_query) ||
                            c.jobTitle
                                .toLowerCase()
                                .contains(_query) ||
                            (c.lastMessage ?? '')
                                .toLowerCase()
                                .contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return AppEmpty(
                    message: _query.isNotEmpty
                        ? 'Aucun résultat pour "$_query"'
                        : 'Aucune conversation pour le moment.',
                    icon: Icons.chat_bubble_outline,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(conversationsProvider.notifier).refresh(),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final conv = filtered[i];
                      return _ConversationTile(
                        conversation: conv,
                        onTap: () => _openChat(context, conv),
                        onJobTap: conv.jobId.isNotEmpty
                            ? () => context.push('/jobs/${conv.jobId}')
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, Conversation conv) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatPage(
        conversationId: conv.conversationId,
        otherUsername: conv.otherUserUsername,
        otherUserId: conv.otherUserId,
        jobId: conv.jobId,
        jobTitle: conv.jobTitle,
      ),
    ));
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────
class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onJobTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    this.onJobTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = conversation.unreadCount > 0;

    // Real-time presence
    final isOnline = conversation.otherUserId.isNotEmpty
        ? (ref
                .watch(presenceProvider(conversation.otherUserId))
                .valueOrNull ??
            false)
        : false;

    return Material(
      color: hasUnread
          ? AppColors.primary.withValues(alpha: 0.03)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────────────
              AvatarWithBadge(
                name: conversation.otherUserUsername,
                size: AppSizes.avatarSm,
                unreadCount: conversation.unreadCount,
                showOnline: isOnline,
              ),
              const SizedBox(width: AppSizes.md),

              // ── Content ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + heure
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUserUsername,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          conversation.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // ── Rappel du job ─────────────────────────────
                    if (conversation.jobTitle.isNotEmpty)
                      GestureDetector(
                        onTap: onJobTap,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_outline,
                                  size: 11, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  conversation.jobTitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onJobTap != null) ...[
                                const SizedBox(width: 2),
                                const Icon(Icons.open_in_new,
                                    size: 10, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                      ),

                    // Dernier message + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin:
                                const EdgeInsets.only(left: AppSizes.sm),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.badge,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
