import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';

/// Birinchi kirishdan keyin — ism va familiya.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key, this.next});
  final String? next;

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _surnameFocus = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _surnameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = S.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = s.firstNameRequired);
      return;
    }
    final session = ref.read(sessionProvider);
    if (session == null) return context.go('/auth/phone');
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updateName(session, name: name, surname: _surname.text.trim());
      await ref.read(profileProvider.notifier).refresh();
      if (!mounted) return;
      context.go(widget.next ?? '/home');
      showSnack(context, s.welcome(name), icon: Icons.waving_hand_rounded);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skip() {
    context.go(widget.next ?? '/home');
    showSnack(context, S.of(context).welcomeNoName, icon: Icons.waving_hand_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Space.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _skip,
                  child: Text(s.later, style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(s.profileSetupTitle, style: context.text.headlineMedium),
              const SizedBox(height: Space.sm),
              Text(s.profileSetupSubtitle, style: context.text.bodyLarge?.copyWith(color: c.textSecondary)),
              const SizedBox(height: Space.xl + 4),
              AutofillGroup(
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      style: context.text.titleMedium,
                      onSubmitted: (_) => _surnameFocus.requestFocus(),
                      decoration: InputDecoration(labelText: s.firstName, errorText: _error),
                    ),
                    const SizedBox(height: Space.md),
                    TextField(
                      controller: _surname,
                      focusNode: _surnameFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.familyName],
                      style: context.text.titleMedium,
                      onSubmitted: (_) => _save(),
                      decoration: InputDecoration(labelText: s.lastName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xxl),
              PrimaryButton(label: s.save, loading: _loading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
