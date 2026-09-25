import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Tashrif vaqtini tanlash: kun (14 kun oldinga) va 3 soatlik oraliq.
/// Bugun o'tib ketgan oraliqlar ko'rsatilmaydi.
class VisitSlot {
  const VisitSlot(this.day, this.from, this.to);
  final DateTime day;
  final String from;
  final String to;
}

const visitWindows = [('09:00', '12:00'), ('12:00', '15:00'), ('15:00', '18:00'), ('18:00', '21:00')];

class VisitPicker extends StatefulWidget {
  const VisitPicker({super.key, required this.onChanged, this.initial});
  final ValueChanged<VisitSlot?> onChanged;
  final VisitSlot? initial;

  @override
  State<VisitPicker> createState() => _VisitPickerState();
}

class _VisitPickerState extends State<VisitPicker> {
  late final List<DateTime> _days;
  late DateTime _day;
  int? _window;

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Bugun hali boshlanmagan (kamida 1 soat oldin) oraliqlar.
  List<int> _free(DateTime day) {
    final now = DateTime.now();
    if (_date(now) != day) return [for (var i = 0; i < visitWindows.length; i++) i];
    return [
      for (var i = 0; i < visitWindows.length; i++)
        if (int.parse(visitWindows[i].$1.substring(0, 2)) > now.hour + 1) i,
    ];
  }

  @override
  void initState() {
    super.initState();
    final today = _date(DateTime.now());
    _days = [for (var i = 0; i < 14; i++) today.add(Duration(days: i))];
    // Bugun bo'sh oraliq qolmagan bo'lsa — ertadan boshlanadi.
    if (_free(today).isEmpty) _days.removeAt(0);
    _day = widget.initial != null ? _date(widget.initial!.day) : _days.first;
    if (widget.initial != null) {
      _window = visitWindows.indexWhere((w) => w.$1 == widget.initial!.from);
      if (_window == -1) _window = null;
    }
  }

  void _emit() {
    final w = _window;
    widget.onChanged(w == null ? null : VisitSlot(_day, visitWindows[w].$1, visitWindows[w].$2));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final loc = Localizations.localeOf(context).languageCode;
    final today = _date(DateTime.now());
    final free = _free(_day);
    String dayName(DateTime d) {
      if (d == today) return s.serviceToday;
      if (d == today.add(const Duration(days: 1))) return s.serviceTomorrow;
      const uz = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
      const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return (loc == 'ru' ? ru : loc == 'en' ? en : uz)[d.weekday - 1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
            itemBuilder: (_, i) {
              final d = _days[i];
              final sel = d == _day;
              return InkWell(
                borderRadius: BorderRadius.circular(Radii.md),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _day = d;
                    if (_window != null && !_free(d).contains(_window)) _window = null;
                  });
                  _emit();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 62,
                  decoration: BoxDecoration(
                    color: sel ? c.accent : c.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: sel ? c.accent : c.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayName(d),
                          maxLines: 1,
                          style: context.text.bodySmall?.copyWith(color: sel ? c.onAccent.withValues(alpha: 0.85) : c.textSecondary)),
                      Text('${d.day}',
                          style: context.text.titleLarge?.copyWith(color: sel ? c.onAccent : c.textPrimary, height: 1.1)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (var i = 0; i < visitWindows.length; i++)
              if (free.contains(i))
                ChoiceChip(
                  selected: _window == i,
                  showCheckmark: false,
                  label: Text('${visitWindows[i].$1}–${visitWindows[i].$2}'),
                  labelStyle: context.text.bodyMedium?.copyWith(
                    color: _window == i ? c.onAccent : c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: c.accent,
                  backgroundColor: c.surface,
                  side: BorderSide(color: _window == i ? c.accent : c.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _window = i);
                    _emit();
                  },
                ),
          ],
        ),
      ],
    );
  }
}
