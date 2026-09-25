import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/ui/widgets.dart';
import '../chat_providers.dart';
import '../data/chat_models.dart';
import 'chat_widgets.dart';

/// Profil → Xabarlar: do'konlar bilan suhbatlar.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.chatsTitle)),
        body: ChatEmpty(
          icon: Icons.forum_outlined,
          title: s.chatsTitle,
          body: s.chatsLoginBody,
          action: PrimaryButton(label: s.signIn, onPressed: () => context.push('/auth/phone?next=%2Fchats')),
        ),
      );
    }

    final chats = ref.watch(chatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.chatsTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(chatsProvider.notifier).refresh(),
        child: chats.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(Space.lg),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: Space.md),
            itemBuilder: (_, _) => const Skeleton(height: 64, radius: Radii.md),
          ),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              if (e is ApiException && e.status == 404)
                ChatEmpty(icon: Icons.forum_outlined, title: s.chatUnavailable, body: s.chatsEmptyBody)
              else
                ErrorRetry(error: e, onRetry: () => ref.invalidate(chatsProvider)),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: ChatEmpty(icon: Icons.forum_outlined, title: s.chatsEmptyTitle, body: s.chatsEmptyBody),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              itemCount: list.length,
              separatorBuilder: (_, _) => Divider(height: 1, indent: 84, color: context.colors.border),
              itemBuilder: (_, i) => _ChatTile(chat: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat});
  final Chat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final last = chat.lastMessage;
    final preview = last == null
        ? ''
        : '${last.mine ? s.chatYou : ''}${last.text.isNotEmpty ? last.text : last.product?.name.of(lang) ?? s.chatProductMsg}';
    final unread = chat.unread > 0;
    return InkWell(
      onTap: () => context.push('/chat/${chat.id}', extra: chat),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.md),
        child: Row(
          children: [
            ChatAvatar(logoUrl: chat.store.logoUrl, size: 52),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium,
                        ),
                      ),
                      if (last != null)
                        Text(
                          chatListTime(context, last.createdAt),
                          style: context.text.bodySmall?.copyWith(color: unread ? c.accent : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (last != null && last.mine) ...[
                        ReadTicks(read: last.id != 0 && last.id <= chat.peerLastReadId, size: 16),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyMedium?.copyWith(color: unread ? c.textPrimary : c.textSecondary),
                        ),
                      ),
                      if (unread) ...[const SizedBox(width: Space.sm), UnreadBadge(count: chat.unread)],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
