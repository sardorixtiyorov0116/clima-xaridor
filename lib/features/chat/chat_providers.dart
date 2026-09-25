import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'chat_socket.dart';
import 'data/chat_models.dart';
import 'data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository(ref.read(apiClientProvider)));

/// Hozir ekranda ochiq suhbat — uning xabarlari uchun bildirishnoma chiqmaydi
/// va o'qilmaganlar soni oshmaydi.
class ActiveChat extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? id) => state = id;

  /// Ekran yopildi — faqat hali o'sha suhbat bo'lsa tozalanadi.
  void clear(int? id) {
    if (!ref.mounted) return; // konteyner yopilgan (ilova yopilmoqda)
    if (state == id) state = null;
  }
}

final activeChatProvider = NotifierProvider<ActiveChat, int?>(ActiveChat.new);

/// Suhbatlar ro'yxati. Socketdan kelgan xabarlar bilan joyida yangilanadi.
class ChatsController extends AsyncNotifier<List<Chat>> {
  @override
  Future<List<Chat>> build() async {
    // Faqat foydalanuvchi almashganda — token yangilanishida ro'yxat qayta yuklanmaydi.
    final userId = ref.watch(sessionProvider.select((s) => s?.userId));
    if (userId == null) return const [];
    // Avval ro'yxat: backend chatni hali qo'llamasa socket behuda ulanib yurmasin.
    final list = await ref.read(chatRepositoryProvider).chats();
    final socket = ref.read(chatSocketProvider);
    final sub = socket.events.listen(_onEvent);
    final sub2 = socket.reconnected.listen((_) => refresh());
    ref.onDispose(() {
      sub.cancel();
      sub2.cancel();
    });
    return _sorted(list);
  }

  static List<Chat> _sorted(List<Chat> l) => [...l]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> refresh() async {
    try {
      state = AsyncData(_sorted(await ref.read(chatRepositoryProvider).chats()));
    } catch (_) {
      // Tarmoq yo'q — mavjud ro'yxat qoladi.
    }
  }

  void _onEvent(ChatEvent e) {
    final list = state.value;
    if (list == null) return;
    switch (e) {
      case ChatMessageEvent(:final message, :final chat):
        final i = list.indexWhere((c) => c.id == e.chatId);
        if (i < 0 && chat == null) {
          refresh(); // yangi suhbat — ro'yxatni qayta olamiz
          return;
        }
        final open = ref.read(activeChatProvider) == e.chatId;
        final base = chat ?? list[i];
        final updated = base.copyWith(
          lastMessage: message,
          updatedAt: message.createdAt,
          unread: open || message.mine ? 0 : (chat?.unread ?? list[i].unread + 1),
        );
        state = AsyncData(_sorted([updated, ...list.where((c) => c.id != e.chatId)]));
      case ChatReadEvent(:final lastMessageId):
        state = AsyncData([for (final c in list) c.id == e.chatId ? c.copyWith(peerLastReadId: lastMessageId) : c]);
      case ChatTypingEvent():
        break;
    }
  }

  /// Suhbat ochilib o'qilganda — belgini darhol olib tashlaymiz.
  void markSeen(int chatId) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([for (final c in list) c.id == chatId ? c.copyWith(unread: 0) : c]);
  }

  /// O'zimiz yuborgan xabar — ro'yxatda yuqoriga chiqsin.
  void upsert(Chat chat) {
    final list = state.value ?? const [];
    state = AsyncData(_sorted([chat, ...list.where((c) => c.id != chat.id)]));
  }
}

final chatsProvider = AsyncNotifierProvider<ChatsController, List<Chat>>(ChatsController.new);

/// Profildagi va sarlavhadagi belgi uchun.
final chatUnreadProvider = Provider<int>((ref) {
  final list = ref.watch(chatsProvider).value ?? const [];
  return list.fold(0, (a, c) => a + c.unread);
});
