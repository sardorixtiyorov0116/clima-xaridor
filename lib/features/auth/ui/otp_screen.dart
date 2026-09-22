import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/code_input.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/phone_input.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

class OtpArgs {
  const OtpArgs({required this.phone, required this.sent, this.consent, this.next});
  final String phone;
  final CodeSent sent;
  final Consent? consent;
  final String? next;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});
  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  final _inputKey = GlobalKey<CodeInputState>();
  late CodeSent _sent = widget.args.sent;

  Timer? _timer;
  int _left = AppConfig.otpResendSeconds;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenSms();
    _code.addListener(() {
      if (_error != null && _code.text.length < AppConfig.otpLength) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SmartAuth.instance.removeUserConsentApiListener();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = AppConfig.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      if (mounted) setState(() => _left--);
    });
  }

  /// Android SMS User Consent: tizim "Climavent SMS'dagi kodni o'qisinmi?" deb so'raydi.
  /// SMS matniga ilova xeshini qo'shish shart emas — Eskiz shablonini o'zgartirmaymiz.
  Future<void> _listenSms() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final r = await SmartAuth.instance.getSmsWithUserConsentApi(matcher: r'\b\d{5}\b');
    final code = r.data?.code;
    if (!mounted || code == null || code.length != AppConfig.otpLength) return;
    _code.text = code;
  }

  Future<void> _verify(String code) async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final r = await ref.read(authRepositoryProvider).verify(
            phone: widget.args.phone,
            sent: _sent,
            code: code,
            consent: widget.args.consent,
          );
      HapticFeedback.mediumImpact();
      await ref.read(sessionProvider.notifier).signIn(r.session, r.profile);
      if (!mounted) return;
      final next = widget.args.next;
      if (!r.profile.hasName) {
        context.go(next == null ? '/auth/name' : '/auth/name?next=${Uri.encodeComponent(next)}');
      } else {
        context.go(next ?? '/home');
        showSnack(context, S.of(context).welcome(r.profile.name!), icon: Icons.waving_hand_rounded);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final s = S.of(context);
      final msg = e.message ?? '';
      String text;
      if (msg == 'Tasdiqlash kodi xato') {
        text = s.otpWrong;
      } else if (msg == 'Tasdiqlash kodi muddati tugagan') {
        text = s.otpExpired;
      } else {
        text = errorText(context, e);
      }
      setState(() => _error = text);
      _inputKey.currentState?.shake();
      _code.clear();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final r = await ref
          .read(authRepositoryProvider)
          .requestCode(widget.args.phone, consent: widget.args.consent);
      if (!mounted) return;
      if (r is CodeSent) {
        _sent = r;
        _code.clear();
        _startTimer();
        _listenSms();
        showSnack(context, S.of(context).otpResent, icon: Icons.sms_outlined);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, errorText(context, e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Space.md),
              const CircleBackButton(),
              const SizedBox(height: Space.xxl + 8),
              Text(s.otpTitle, style: context.text.headlineMedium),
              const SizedBox(height: Space.sm),
              Text.rich(
                TextSpan(
                  style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
                  children: _subtitleSpans(s.otpSubtitle('\u{2063}'), prettyPhone(widget.args.phone),
                      context.text.bodyLarge?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: Space.xxl),
              CodeInput(
                key: _inputKey,
                controller: _code,
                length: AppConfig.otpLength,
                hasError: _error != null,
                enabled: !_verifying,
                onCompleted: _verify,
              ),
              const SizedBox(height: Space.md),
              SizedBox(
                height: 24,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _verifying
                      ? Row(
                          key: const ValueKey('v'),
                          children: [
                            SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
                            const SizedBox(width: 8),
                            Text(s.otpVerifying, style: context.text.bodyMedium),
                          ],
                        )
                      : _error != null
                          ? Text(_error!,
                              key: ValueKey(_error),
                              style: context.text.bodyMedium?.copyWith(color: c.danger))
                          : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: Space.xl),
              Center(
                child: _left > 0
                    ? Text(s.otpResendIn('$mm:$ss'),
                        style: context.text.bodyMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()]))
                    : TextButton.icon(
                        onPressed: _resending ? null : _resend,
                        icon: _resending
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded),
                        label: Text(s.otpResend),
                      ),
              ),
              const SizedBox(height: Space.sm),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(s.otpChangeNumber,
                      style: context.text.titleMedium?.copyWith(color: c.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjimadagi `{phone}` o'rniga qalin raqam qo'yamiz — til tartibi saqlanadi.
  static List<InlineSpan> _subtitleSpans(String template, String phone, TextStyle? bold) {
    final parts = template.split('\u{2063}');
    return [
      TextSpan(text: parts.first),
      TextSpan(text: '⁠$phone⁠', style: bold),
      if (parts.length > 1) TextSpan(text: parts[1]),
    ];
  }
}
