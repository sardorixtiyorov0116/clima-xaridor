import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// SMS-kod uchun katakchalar. Ichida bitta yashirin TextField —
/// shuning uchun joylashtirish, iOS "kodni SMS'dan olish" va
/// klaviaturadagi taklif ishlaydi.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.length,
    required this.onCompleted,
    this.focusNode,
    this.hasError = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String> onCompleted;
  final FocusNode? focusNode;
  final bool hasError;
  final bool enabled;

  @override
  State<CodeInput> createState() => CodeInputState();
}

class CodeInputState extends State<CodeInput> with SingleTickerProviderStateMixin {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  /// Xato bo'lganda chaqiriladi: katakchalar silkinadi va telefon titraydi.
  void shake() {
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _focus.addListener(() => setState(() {}));
  }

  void _onChange() {
    setState(() {});
    final v = widget.controller.text;
    if (v.length == widget.length) widget.onCompleted(v);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    if (widget.focusNode == null) _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = widget.controller.text;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focus.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        },
        child: Stack(
          children: [
            // Yashirin maydon — barcha kiritishni qabul qiladi.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: '', filled: false),
                ),
              ),
            ),
            IgnorePointer(
              child: LayoutBuilder(builder: (context, box) {
               final cell = math.min(58.0, (box.maxWidth - 10.0 * (widget.length - 1)) / widget.length);
               return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (i) {
                  final filled = i < value.length;
                  final active = _focus.hasFocus && i == value.length.clamp(0, widget.length - 1) &&
                      value.length < widget.length;
                  final borderColor = widget.hasError
                      ? c.danger
                      : active
                          ? c.accent
                          : filled
                              ? c.border
                              : Colors.transparent;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: cell,
                    height: cell * 1.14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.hasError
                          ? c.danger.withValues(alpha: 0.06)
                          : filled
                              ? c.surface
                              : c.surfaceMuted,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: borderColor, width: 1.6),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                      child: filled
                          ? Text(
                              value[i],
                              key: ValueKey('d$i${value[i]}'),
                              style: context.text.headlineMedium?.copyWith(
                                color: widget.hasError ? c.danger : c.textPrimary,
                              ),
                            )
                          : active
                              ? _Caret(color: c.accent)
                              : const SizedBox.shrink(),
                    ),
                  );
                }),
              );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret({required this.color});
  final Color color;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: Container(width: 2, height: 28, color: widget.color),
      );
}
