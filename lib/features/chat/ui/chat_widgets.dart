import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/ui/widgets.dart';

/// Ro'yxatdagi vaqt: bugun — soat, kecha — "Kecha", undan oldin — sana.
String chatListTime(BuildContext context, DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  if (day == today) return DateFormat.Hm().format(t);
  if (today.difference(day).inDays == 1) return S.of(context).chatYesterday;
  return DateFormat('dd.MM.yy').format(t);
}

/// Xabarlar orasidagi kun ajratgichi.
String chatDayLabel(BuildContext context, DateTime t) {
  final s = S.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return s.chatToday;
  if (diff == 1) return s.chatYesterday;
  return DateFormat('dd.MM.yyyy').format(t);
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, this.logoUrl, this.size = 40});
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: c.border),
      ),
      child: logoUrl == null
          ? Icon(Icons.storefront_outlined, size: size * 0.5, color: c.textTertiary)
          : Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: NetImage(logoUrl, width: (size * 4).round()),
            ),
    );
  }
}

class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(11)),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: context.text.labelSmall?.copyWith(color: c.onAccent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// ✓ — yuborildi, ✓✓ — do'kon o'qidi.
class ReadTicks extends StatelessWidget {
  const ReadTicks({super.key, required this.read, this.size = 15, this.color});
  final bool read;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final col = color ?? (read ? (dark ? Brand.sky : Brand.link) : context.colors.textTertiary);
    return Icon(read ? Icons.done_all_rounded : Icons.done_rounded, size: size, color: col);
  }
}

class ChatEmpty extends StatelessWidget {
  const ChatEmpty({super.key, required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: c.textTertiary),
            ),
            const SizedBox(height: Space.lg),
            Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
            const SizedBox(height: Space.sm),
            Text(body, textAlign: TextAlign.center, style: context.text.bodyMedium),
            if (action != null) ...[const SizedBox(height: Space.xl), action!],
          ],
        ),
      ),
    );
  }
}
