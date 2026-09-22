import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/phone_input.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import 'otp_screen.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key, this.firstRun = false, this.next});

  /// Onboardingdan keyin — "Keyinroq" bosh sahifaga olib boradi.
  final bool firstRun;

  /// Kirgandan keyin qaytiladigan sahifa (masalan, `/checkout?kind=order`).
  final String? next;

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  String? _error;

  String get _digits => _ctrl.text.replaceAll(RegExp(r'\D'), '');
  String get _e164 => '+998$_digits';
  bool get _valid => isValidUzMobile(_digits);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit({Consent? consent}) async {
    if (!_valid) {
      setState(() => _error = S.of(context).phoneInvalid);
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await ref.read(authRepositoryProvider).requestCode(_e164, consent: consent);
      if (!mounted) return;
      switch (r) {
        case ConsentRequired():
          setState(() => _loading = false);
          final accepted = await showConsentSheet(context);
          if (accepted == true && mounted) {
            await _submit(consent: Consent(r.termsVersion, r.privacyVersion));
          }
          return;
        case CodeSent():
          TextInput.finishAutofillContext();
          context.push('/auth/otp', extra: OtpArgs(phone: _e164, sent: r, consent: consent, next: widget.next));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(context, e));
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _later() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final canPop = context.canPop();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Space.md),
                    Row(
                      children: [
                        if (canPop) const CircleBackButton() else const BrandLockup(height: 30),
                        const Spacer(),
                        if (!canPop || widget.firstRun)
                          TextButton(
                            onPressed: _later,
                            child: Text(s.later,
                                style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.xxl + 8),
                    Text(s.phoneTitle, style: context.text.headlineMedium),
                    const SizedBox(height: Space.sm),
                    Text(s.phoneSubtitle, style: context.text.bodyLarge?.copyWith(color: c.textSecondary)),
                    const SizedBox(height: Space.xl + 4),
                    AutofillGroup(
                      child: PhoneField(
                        controller: _ctrl,
                        focusNode: _focus,
                        errorText: _error,
                        enabled: !_loading,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: Space.xl),
                    PrimaryButton(
                      label: s.getCode,
                      loading: _loading,
                      onPressed: _digits.length == 9 ? () => _submit() : null,
                    ),
                    const SizedBox(height: Space.md),
                    Text(s.phoneFooter, textAlign: TextAlign.center, style: context.text.bodySmall),
                    const SizedBox(height: Space.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yangi raqam uchun rozilik oynasi (foydalanish shartlari 3.2, maxfiylik 4.2).
Future<bool?> showConsentSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ConsentSheet(),
  );
}

class _ConsentSheet extends StatefulWidget {
  const _ConsentSheet();

  @override
  State<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends State<_ConsentSheet> {
  bool _agree = false;
  late final TapGestureRecognizer _terms = TapGestureRecognizer()..onTap = () => _open(AppConfig.termsUrl);
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()..onTap = () => _open(AppConfig.privacyUrl);

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final link = context.text.bodyLarge?.copyWith(
      color: Theme.of(context).brightness == Brightness.dark ? Brand.sky : Brand.link,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter,
          Space.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Brand.mist.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: const Icon(Icons.verified_user_outlined, color: Brand.navy, size: 28),
          ),
          const SizedBox(height: Space.lg),
          Text(s.consentTitle, style: context.text.headlineSmall),
          const SizedBox(height: Space.sm),
          Text(s.consentBody, style: context.text.bodyMedium),
          const SizedBox(height: Space.xl),
          InkWell(
            borderRadius: BorderRadius.circular(Radii.md),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _agree = !_agree);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: _agree ? c.accent : Colors.transparent, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(style: context.text.bodyLarge, children: [
                        TextSpan(text: s.consentPrefix),
                        TextSpan(text: s.consentTerms, style: link, recognizer: _terms),
                        TextSpan(text: s.consentAnd),
                        TextSpan(text: s.consentPrivacy, style: link, recognizer: _privacy),
                        TextSpan(text: s.consentSuffix),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          PrimaryButton(
            label: s.consentAccept,
            onPressed: _agree ? () => Navigator.of(context).pop(true) : null,
          ),
        ],
      ),
    );
  }
}
