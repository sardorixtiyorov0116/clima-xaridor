import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';

class CheckoutDoneScreen extends StatefulWidget {
  const CheckoutDoneScreen({super.key, required this.kind, required this.ids});
  final String kind;
  final List<String> ids;

  @override
  State<CheckoutDoneScreen> createState() => _CheckoutDoneScreenState();
}

class _CheckoutDoneScreenState extends State<CheckoutDoneScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final quote = widget.kind == 'quote';
    final numbers = widget.ids.map((e) => '#$e').join(', ');
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: CurvedAnimation(parent: _a, curve: Curves.elasticOut),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(color: c.success.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(quote ? Icons.request_quote_rounded : Icons.check_circle_rounded,
                      size: 64, color: c.success),
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(quote ? s.doneQuoteTitle : s.doneOrderTitle,
                  textAlign: TextAlign.center, style: context.text.headlineSmall),
              const SizedBox(height: Space.sm),
              Text(s.doneNumbers(numbers), textAlign: TextAlign.center, style: context.text.titleMedium),
              const SizedBox(height: Space.md),
              Text(quote ? s.doneQuoteBody : s.doneOrderBody,
                  textAlign: TextAlign.center, style: context.text.bodyMedium),
              const Spacer(flex: 2),
              PrimaryButton(label: s.myOrders, onPressed: () => context.go('/orders')),
              const SizedBox(height: Space.sm),
              GhostButton(label: s.continueShopping, onPressed: () => context.go('/home')),
              const SizedBox(height: Space.lg),
            ],
          ),
        ),
      ),
    );
  }
}
