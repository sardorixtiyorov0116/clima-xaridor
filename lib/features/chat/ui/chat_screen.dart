import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/data/models.dart' show Store;
import '../../catalog/ui/widgets.dart';
import '../chat_providers.dart';
import '../chat_socket.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';
import 'chat_widgets.dart';

/// Do'kon bilan yozishish.
/// - `/chat/:id` — ro'yxat yoki push'dan;
/// - `/chat/store/:storeId?product=` — mahsulot sahifasidan (suhbat bo'lmasa ochiladi,
///   mahsulot birinchi xabarga biriktiriladi).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.chatId, this.storeId, this.productId, this.initial, this.store});
  final int? chatId;
  final int? storeId;
  final int? productId;
  final Chat? initial;

  /// Mahsulot sahifasidan kelganda — sarlavha suhbat yuklanguncha ham to'la tursin.
  final Store? store;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _page = 30;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _subs = <StreamSubscription<Object?>>[];
  // initState da olinadi: dispose paytida `ref` ishlatib bo'lmaydi.
  late final ChatSocket _socket;
  late final ActiveChat _active;

  Chat? _chat;
  List<ChatMessage> _msgs = const []; // yangidan eskiga
  bool _loading = true;
  Object? _error;
  bool _hasMore = false;
  bool _loadingMore = false;
  int _peerRead = 0;
  int _lastMarked = 0;
  bool _peerTyping = false;
  Timer? _typingTimer;
  int? _attach;

  @override
  void initState() {
    super.initState();
    _socket = ref.read(chatSocketProvider);
    _active = ref.read(activeChatProvider.notifier);
    _attach = widget.productId;
    _chat = widget.initial;
    _input.addListener(() => setState(() {}));
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
    _subs
      ..add(_socket.events.listen(_onEvent))
      ..add(_socket.reconnected.listen((_) => _loadLatest().catchError((_) {})));
    // Birinchi kadrdan keyin: ekran qurilayotganda provider'ni o'zgartirib bo'lmaydi.
    if (ref.read(sessionProvider) != null) WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _typingTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    final id = _chat?.id;
    final active = _active;
    // Provider'ni daraxt yig'ilayotgan paytda o'zgartirib bo'lmaydi.
    Future.microtask(() => active.clear(id));
    super.dispose();
  }

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var chat = _chat;
      if (chat == null) {
        final id = widget.chatId;
        if (id != null) {
          final cached = ref.read(chatsProvider).value?.where((c) => c.id == id);
          chat = cached != null && cached.isNotEmpty ? cached.first : await _repo.chat(id);
        } else {
          chat = await _repo.open(widget.storeId ?? 0);
        }
      }
      if (!mounted) return;
      _chat = chat;
      _peerRead = chat.peerLastReadId;
      _active.set(chat.id);
      await _loadLatest();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Oxirgi sahifa. Yuborilayotgan (serverda hali yo'q) xabarlar saqlanib qoladi.
  Future<void> _loadLatest() async {
    final chat = _chat;
    if (chat == null) return;
    try {
      // Ro'yxat ham yangilanadi: `peer_last_read_id` suhbat obyektida keladi (xabarlar javobida yo'q).
      final list = ref.read(chatsProvider.notifier).refresh();
      final r = await _repo.messages(chat.id, limit: _page);
      await list;
      if (!mounted) return;
      var peer = r.peerLastReadId;
      for (final c in ref.read(chatsProvider).value ?? const <Chat>[]) {
        if (c.id == chat.id && c.peerLastReadId > peer) peer = c.peerLastReadId;
      }
      // Qarshi tomon javob yozgan bo'lsa — undan oldingi xabarlarni ko'rgan.
      final theirs = r.items.where((m) => !m.mine).firstOrNull?.id ?? 0;
      if (theirs > peer) peer = theirs;
      final pending = _msgs.where((m) => m.id == 0 && !r.items.any(m.sameAs));
      final older = _msgs.where((m) => m.id != 0 && r.items.isNotEmpty && m.id < r.items.last.id);
      setState(() {
        _msgs = [...pending, ...r.items, ...older];
        if (older.isEmpty) _hasMore = r.items.length >= _page;
        if (peer > _peerRead) _peerRead = peer;
      });
      _markRead();
    } catch (e) {
      if (_msgs.isEmpty) rethrow;
    }
  }

  Future<void> _loadMore() async {
    final chat = _chat;
    if (chat == null || !_hasMore || _loadingMore) return;
    final oldest = _msgs.lastWhere((m) => m.id != 0, orElse: () => _msgs.last).id;
    if (oldest == 0) return;
    setState(() => _loadingMore = true);
    try {
      final r = await _repo.messages(chat.id, beforeId: oldest, limit: _page);
      if (!mounted) return;
      setState(() {
        _msgs = [..._msgs, ...r.items.where((m) => !_msgs.any(m.sameAs))];
        _hasMore = r.items.length >= _page;
      });
    } catch (_) {
      // keyingi aylantirishda qayta uriniladi
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onEvent(ChatEvent e) {
    final chat = _chat;
    if (chat == null || e.chatId != chat.id || !mounted) return;
    switch (e) {
      case ChatMessageEvent(:final message):
        setState(() {
          final i = _msgs.indexWhere(message.sameAs);
          if (i >= 0) {
            _msgs = [..._msgs]..[i] = message;
          } else {
            _msgs = [message, ..._msgs];
          }
          if (!message.mine) {
            _peerTyping = false;
            // Javob yozgan tomon oldingi xabarlarni ko'rgan — ✓✓ darhol.
            if (message.id > _peerRead) _peerRead = message.id;
          }
        });
        if (!message.mine) {
          HapticFeedback.selectionClick();
          _markRead();
        }
      case ChatReadEvent(:final lastMessageId):
        if (lastMessageId > _peerRead) setState(() => _peerRead = lastMessageId);
      case ChatTypingEvent():
        setState(() => _peerTyping = true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _peerTyping = false);
        });
    }
  }

  void _markRead() {
    final chat = _chat;
    if (chat == null) return;
    final newest = _msgs.where((m) => m.id != 0).firstOrNull?.id ?? 0;
    ref.read(chatsProvider.notifier).markSeen(chat.id);
    if (newest <= _lastMarked) return;
    _lastMarked = newest;
    _repo.markRead(chat.id, newest).catchError((_) {});
  }

  Future<void> _send([String? quick]) async {
    final chat = _chat;
    if (chat == null) return;
    final text = (quick ?? _input.text).trim();
    final attach = _attach;
    if (text.isEmpty && attach == null) return;
    final product = attach == null ? null : ref.read(productDetailProvider(attach)).value;
    final local = ChatMessage(
      id: 0,
      chatId: chat.id,
      mine: true,
      text: text,
      product: product == null ? null : ChatProduct(id: product.id, name: product.name, image: product.cover),
      clientMsgId: const Uuid().v4(),
      createdAt: DateTime.now(),
      state: SendState.sending,
    );
    HapticFeedback.lightImpact();
    setState(() {
      _msgs = [local, ..._msgs];
      _attach = null;
      if (quick == null) _input.clear();
    });
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    await _deliver(local, productId: attach);
  }

  Future<void> _deliver(ChatMessage m, {int? productId}) async {
    try {
      final saved = await _repo.send(
        m.chatId,
        text: m.text,
        productId: productId ?? m.product?.id,
        clientMsgId: m.clientMsgId!,
      );
      if (!mounted) return;
      setState(() {
        final i = _msgs.indexWhere(saved.sameAs);
        if (i >= 0) _msgs = [..._msgs]..[i] = saved;
      });
      _lastMarked = saved.id > _lastMarked ? saved.id : _lastMarked;
      ref
          .read(chatsProvider.notifier)
          .upsert(
            _chat!.copyWith(lastMessage: saved, updatedAt: saved.createdAt, unread: 0, peerLastReadId: _peerRead),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final i = _msgs.indexWhere(m.sameAs);
        if (i >= 0) _msgs = [..._msgs]..[i] = m.copyWith(state: SendState.failed);
      });
    }
  }

  void _retry(ChatMessage m) {
    setState(() {
      final i = _msgs.indexWhere(m.sameAs);
      if (i >= 0) _msgs = [..._msgs]..[i] = m.copyWith(state: SendState.sending);
    });
    _deliver(m);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final session = ref.watch(sessionProvider);
    final storeName = _chat?.store.name ?? widget.store?.name ?? '';
    final logo = _chat?.store.logoUrl ?? widget.store?.logoUrl;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: Row(
          children: [
            ChatAvatar(logoUrl: logo, size: 38),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(storeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                  ValueListenableBuilder<bool>(
                    valueListenable: _socket.connected,
                    builder: (_, online, _) {
                      final connecting = !online && _chat != null && !_socket.forbidden;
                      final sub = _peerTyping ? s.chatTyping : (connecting ? s.chatConnecting : null);
                      if (sub == null) return const SizedBox.shrink();
                      return Text(
                        sub,
                        style: context.text.bodySmall?.copyWith(color: _peerTyping ? c.accent : c.textTertiary),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: session == null
          ? ChatEmpty(
              icon: Icons.forum_outlined,
              title: s.chatsTitle,
              body: s.chatsLoginBody,
              action: PrimaryButton(
                label: s.signIn,
                onPressed: () =>
                    context.push('/auth/phone?next=${Uri.encodeComponent(GoRouterState.of(context).uri.toString())}'),
              ),
            )
          : Column(
              children: [
                Expanded(child: _body(s, c)),
                if (_chat != null) _composer(s, c),
              ],
            ),
    );
  }

  Widget _body(S s, AppColors c) {
    if (_loading && _msgs.isEmpty) return const Center(child: CircularProgressIndicator());
    final err = _error;
    if (err != null && _msgs.isEmpty) {
      if (err is ApiException && err.status == 404) {
        return ChatEmpty(icon: Icons.forum_outlined, title: s.chatUnavailable, body: s.chatsEmptyBody);
      }
      return Center(
        child: ErrorRetry(error: err, onRetry: _init),
      );
    }
    if (_msgs.isEmpty) {
      return LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: ChatEmpty(
              icon: Icons.chat_bubble_outline_rounded,
              title: s.chatEmptyTitle,
              body: s.chatEmptyBody,
              action: Wrap(
                alignment: WrapAlignment.center,
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final q in [s.chatQuickPrice, s.chatQuickStock, s.chatQuickDelivery])
                    ActionChip(
                      label: Text(q),
                      onPressed: () => _send(q),
                      side: BorderSide(color: c.border),
                      backgroundColor: c.surface,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.sm),
        itemCount: _msgs.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _msgs.length) {
            return const Padding(
              padding: EdgeInsets.all(Space.lg),
              child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final m = _msgs[i];
          final older = i + 1 < _msgs.length ? _msgs[i + 1] : null;
          final newer = i > 0 ? _msgs[i - 1] : null;
          final newDay = older == null || !_sameDay(older.createdAt, m.createdAt);
          final groupedWithNewer = newer != null && newer.mine == m.mine && _sameDay(newer.createdAt, m.createdAt);
          return Column(
            children: [
              if (newDay) _DaySeparator(label: chatDayLabel(context, m.createdAt)),
              Padding(
                padding: EdgeInsets.only(bottom: groupedWithNewer ? 2 : Space.sm),
                child: _Bubble(message: m, read: m.mine && m.id != 0 && m.id <= _peerRead, onRetry: () => _retry(m)),
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _composer(S s, AppColors c) {
    final attach = _attach;
    final canSend = _input.text.trim().isNotEmpty || attach != null;
    return Material(
      color: c.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border)),
          ),
          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attach != null) _AttachPreview(productId: attach, onClose: () => setState(() => _attach = null)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      onChanged: (_) {
                        final id = _chat?.id;
                        if (id != null) _socket.typing(id);
                      },
                      decoration: InputDecoration(
                        hintText: s.chatInputHint,
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: c.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: c.accent.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  AnimatedScale(
                    scale: canSend ? 1 : 0.85,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton.filled(
                      onPressed: canSend ? _send : null,
                      style: IconButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.onAccent,
                        disabledBackgroundColor: c.surfaceMuted,
                        disabledForegroundColor: c.textTertiary,
                        fixedSize: const Size(46, 46),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 22),
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

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: context.text.labelSmall?.copyWith(color: c.textSecondary)),
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.read, required this.onRetry});
  final ChatMessage message;
  final bool read;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final m = message;
    final lang = ref.watch(langProvider);
    final bg = m.mine ? c.accent : c.surface;
    final fg = m.mine ? c.onAccent : c.textPrimary;
    final meta = m.mine ? c.onAccent.withValues(alpha: 0.7) : c.textTertiary;
    final failed = m.state == SendState.failed;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(m.mine ? 18 : 6),
          bottomRight: Radius.circular(m.mine ? 6 : 18),
        ),
        border: m.mine ? null : Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.product != null) ...[
            _ProductInBubble(product: m.product!, lang: lang, mine: m.mine),
            if (m.text.isNotEmpty) const SizedBox(height: 6),
          ],
          if (m.text.isNotEmpty) Text(m.text, style: context.text.bodyLarge?.copyWith(color: fg, height: 1.3)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              Text(DateFormat.Hm().format(m.createdAt), style: context.text.labelSmall?.copyWith(color: meta)),
              if (m.mine) ...[
                const SizedBox(width: 4),
                switch (m.state) {
                  SendState.sending => Icon(Icons.schedule_rounded, size: 14, color: meta),
                  SendState.failed => Icon(Icons.error_outline_rounded, size: 15, color: c.danger),
                  SendState.sent => ReadTicks(
                    read: read,
                    size: 15,
                    // Pufakcha foniga qarama-qarshi: kunduzi to'q ko'k ustida moviy, tunda moviy ustida to'q ko'k.
                    color: read ? (Theme.of(context).brightness == Brightness.dark ? c.onAccent : Brand.sky) : meta,
                  ),
                },
              ],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: failed ? onRetry : null,
            onLongPress: m.text.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: m.text));
                    HapticFeedback.mediumImpact();
                    showSnack(context, MaterialLocalizations.of(context).copyButtonLabel, icon: Icons.copy_rounded);
                  },
            child: IntrinsicWidth(child: bubble),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 4),
              child: Text(s.chatFailed, style: context.text.labelSmall?.copyWith(color: c.danger)),
            ),
        ],
      ),
    );
  }
}

class _ProductInBubble extends StatelessWidget {
  const _ProductInBubble({required this.product, required this.lang, required this.mine});
  final ChatProduct product;
  final String lang;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = mine ? c.onAccent : c.textPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: mine ? Colors.white.withValues(alpha: 0.12) : c.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: NetImage(product.image, width: 120),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                product.name.of(lang),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: fg.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

/// Yuborishdan oldin biriktirilgan mahsulot.
class _AttachPreview extends ConsumerWidget {
  const _AttachPreview({required this.productId, required this.onClose});
  final int productId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = context.colors;
    final lang = ref.watch(langProvider);
    final p = ref.watch(productDetailProvider(productId)).value;
    if (p == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Container(width: 3, height: 40, color: c.accent),
          const SizedBox(width: Space.sm),
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: NetImage(p.cover, width: 120),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.chatAboutProduct, style: context.text.labelSmall?.copyWith(color: c.accent)),
                Text(p.name.of(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 20)),
        ],
      ),
    );
  }
}
