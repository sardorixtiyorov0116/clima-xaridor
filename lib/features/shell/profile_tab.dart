import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/phone_input.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/ui/widgets.dart' show Skeleton;
import '../chat/chat_providers.dart';
import '../chat/ui/chat_widgets.dart' show UnreadBadge;
import '../onboarding/language_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final session = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider);
    final locale = ref.watch(localeProvider) ?? Localizations.localeOf(context);
    final theme = ref.watch(themeModeProvider);
    final langName = languageOptions
        .firstWhere((o) => o.locale.languageCode == locale.languageCode, orElse: () => languageOptions.first)
        .native;
    final themeName = switch (theme) {
      ThemeMode.light => s.themeLight,
      ThemeMode.dark => s.themeDark,
      ThemeMode.system => s.themeSystem,
    };

    return Scaffold(
      appBar: AppBar(title: Text(s.tabProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl),
        children: [
          if (session == null)
            const _GuestCard()
          else
            _UserCard(
              name: profile?.displayName ?? '',
              initials: profile?.initials ?? '',
              phone: prettyPhone(session.phone),
              loading: profile == null,
            ),
          const SizedBox(height: Space.xl),
          _Group(children: [
            _Row(
              icon: Icons.forum_outlined,
              title: s.chatsTitle,
              badge: ref.watch(chatUnreadProvider),
              onTap: () => context.push('/chats'),
            ),
            _Row(
              icon: Icons.favorite_border_rounded,
              title: s.favoritesTitle,
              onTap: () => context.push('/favorites'),
            ),
          ]),
          const SizedBox(height: Space.lg),
          _Group(children: [
            _Row(
              icon: Icons.translate_rounded,
              title: s.settingsLanguage,
              value: langName,
              onTap: () => _pickLanguage(context, ref),
            ),
            _Row(
              icon: Icons.dark_mode_outlined,
              title: s.settingsTheme,
              value: themeName,
              onTap: () => _pickTheme(context, ref),
            ),
          ]),
          const SizedBox(height: Space.lg),
          _Group(children: [
            _Row(
              icon: Icons.support_agent_rounded,
              title: s.settingsSupport,
              subtitle: AppConfig.supportPhoneLabel,
              onTap: () => launchUrl(Uri.parse('tel:${AppConfig.supportPhone}')),
            ),
            _Row(
              icon: Icons.description_outlined,
              title: s.settingsTerms,
              onTap: () => launchUrl(Uri.parse(AppConfig.termsUrl), mode: LaunchMode.inAppBrowserView),
            ),
            _Row(
              icon: Icons.shield_outlined,
              title: s.settingsPrivacy,
              onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl), mode: LaunchMode.inAppBrowserView),
            ),
          ]),
          if (session != null) ...[
            const SizedBox(height: Space.lg),
            _Group(children: [
              _Row(
                icon: Icons.logout_rounded,
                title: s.signOut,
                danger: true,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ]),
          ],
          const SizedBox(height: Space.xl),
          // Uzoq bosilsa — push tokeni nusxalanadi (Firebase'dan sinov xabari yuborish uchun).
          Center(
            child: GestureDetector(
              onLongPress: () async {
                final token = await FirebaseMessaging.instance.getToken();
                if (token == null || !context.mounted) return;
                await Clipboard.setData(ClipboardData(text: token));
                if (context.mounted) showSnack(context, s.pushTokenCopied, icon: Icons.copy_rounded);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(s.version(AppConfig.appVersion), style: context.text.bodySmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final cur = ref.watch(localeProvider) ?? Localizations.localeOf(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(ctx).langTitle, style: ctx.text.headlineSmall),
              const SizedBox(height: Space.lg),
              for (final o in languageOptions) ...[
                LanguageTile(
                  option: o,
                  selected: o.locale.languageCode == cur.languageCode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(localeProvider.notifier).set(o.locale);
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: Space.md),
              ],
            ],
          ),
        );
      }),
    );
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final cur = ref.watch(themeModeProvider);
        Widget opt(ThemeMode m, String label, IconData icon) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              leading: Icon(icon),
              title: Text(label, style: ctx.text.titleMedium),
              trailing: cur == m ? Icon(Icons.check_rounded, color: ctx.colors.accent) : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).set(m);
                Navigator.of(ctx).pop();
              },
            );
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            opt(ThemeMode.system, s.themeSystem, Icons.brightness_auto_outlined),
            opt(ThemeMode.light, s.themeLight, Icons.light_mode_outlined),
            opt(ThemeMode.dark, s.themeDark, Icons.dark_mode_outlined),
            const SizedBox(height: Space.md),
          ]),
        );
      }),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.signOutConfirm, style: ctx.text.titleLarge),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colors.danger),
            child: Text(s.signOut),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).signOut();
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Brand.mist.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Brand.navy, size: 28),
          ),
          const SizedBox(height: Space.lg),
          Text(s.guestTitle, style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(s.guestBody, style: context.text.bodyMedium),
          const SizedBox(height: Space.lg),
          PrimaryButton(label: s.signIn, onPressed: () => context.push('/auth/phone')),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.name, required this.initials, required this.phone, this.loading = false});
  final String name;
  final String initials;
  final String phone;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          if (loading)
            const Skeleton(width: 56, height: 56, radius: 28)
          else
            CircleAvatar(
              radius: 28,
              backgroundColor: c.accent,
              child: initials.isEmpty
                  ? Icon(Icons.person_rounded, color: c.onAccent)
                  : Text(initials, style: context.text.titleLarge?.copyWith(color: c.onAccent)),
            ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading)
                  const Padding(padding: EdgeInsets.only(bottom: 6), child: Skeleton(width: 150, height: 18))
                else if (name.isNotEmpty)
                  Text(name, style: context.text.titleLarge),
                const SizedBox(height: 2),
                Text(phone, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Padding(padding: const EdgeInsets.only(left: 56), child: Divider(color: c.border)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.onTap,
    this.danger = false,
    this.badge = 0,
  });
  final IconData icon;
  final int badge;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = danger ? c.danger : c.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: danger ? c.danger : c.textSecondary, size: 22),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium?.copyWith(color: color)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(value!, style: context.text.bodyMedium),
            if (badge > 0) UnreadBadge(count: badge),
            if (!danger) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: c.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
