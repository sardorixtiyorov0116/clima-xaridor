import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// `901234567` → `90 123 45 67`
String formatUzPhone(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  final b = StringBuffer();
  for (var i = 0; i < d.length && i < 9; i++) {
    if (i == 2 || i == 5 || i == 7) b.write(' ');
    b.write(d[i]);
  }
  return b.toString();
}

/// `+998901234567` → `+998 90 123 45 67`
String prettyPhone(String e164) {
  final d = e164.replaceAll(RegExp(r'\D'), '');
  if (d.length == 12 && d.startsWith('998')) return '+998 ${formatUzPhone(d.substring(3))}';
  return e164;
}

/// Kiritishda bo'shliqlarni o'zi qo'yadi, kursor oxirda qoladi.
class UzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // To'liq raqam joylashtirilsa (+998 90 ...) — prefiksni olib tashlaymiz.
    if (digits.length > 9 && digits.startsWith('998')) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);
    final text = formatUzPhone(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// O'zbekiston operator kodlari (2026): Beeline 90/91, Ucell 93/94/50, Mobiuz 88/97,
/// Uzmobile 95/99/77, Humans 33, Perfectum 98, shaharlik 55/71/78 va boshqalar.
/// Qat'iy tekshirmaymiz — faqat birinchi raqam 0 bo'lmasin.
bool isValidUzMobile(String digits) =>
    digits.length == 9 && !digits.startsWith('0');

/// Katta telefon maydoni: bayroq + `+998` prefiksi + raqam.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.focusNode,
    this.errorText,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final big = context.text.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [UzPhoneFormatter()],
      style: big,
      cursorColor: c.accent,
      onSubmitted: onSubmitted,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: '90 123 45 67',
        hintStyle: big?.copyWith(color: c.textTertiary.withValues(alpha: 0.6)),
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _UzFlag(),
              const SizedBox(width: 10),
              Text('+998', style: big),
              const SizedBox(width: 10),
              Container(width: 1, height: 24, color: c.border),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
      ),
    );
  }
}

/// O'zbekiston bayrog'i — emoji har qurilmada bir xil chiqmaydi, shuning uchun chizamiz.
class _UzFlag extends StatelessWidget {
  const _UzFlag();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 26,
        height: 18,
        child: Column(
          children: [
            Expanded(flex: 10, child: Container(color: const Color(0xFF1EB4E6))),
            Container(height: 1, color: const Color(0xFFCE1126)),
            Expanded(flex: 10, child: Container(color: Colors.white)),
            Container(height: 1, color: const Color(0xFFCE1126)),
            Expanded(flex: 10, child: Container(color: const Color(0xFF1EB53A))),
          ],
        ),
      ),
    );
  }
}
