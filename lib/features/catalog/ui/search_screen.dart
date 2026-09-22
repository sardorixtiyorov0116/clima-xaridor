import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import 'category_screen.dart';
import 'widgets.dart';

/// Qidiruv qurilmada: nomi (3 til), model va SAP kodi, ishlab chiqaruvchi bo'yicha.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _q = '';
  SortMode _sort = SortMode.popular;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => setState(() => _q = v.trim().toLowerCase()));
  }

  void _use(String v) {
    _ctrl.text = v;
    _ctrl.selection = TextSelection.collapsed(offset: v.length);
    setState(() => _q = v.trim().toLowerCase());
    ref.read(searchHistoryProvider.notifier).push(v);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final products = ref.watch(productsProvider);
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: Space.lg),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (v) => ref.read(searchHistoryProvider.notifier).push(v),
            style: context.text.bodyLarge,
            decoration: InputDecoration(
              hintText: s.searchHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: Icon(Icons.search_rounded, color: c.textTertiary),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, color: c.textTertiary),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _q = '');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: _q.length < 2
          ? _History(history: history, onPick: _use, onClear: () => ref.read(searchHistoryProvider.notifier).clear())
          : products.when(
              loading: () => const CustomScrollView(slivers: [
                SliverToBoxAdapter(child: SizedBox(height: Space.lg)),
                ProductGridSkeleton(count: 4),
              ]),
              error: (e, _) => Center(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(productsProvider))),
              data: (all) {
                final found = applySort(all.where((p) => p.matches(_q)).toList(), _sort);
                if (found.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: c.textTertiary),
                          const SizedBox(height: Space.lg),
                          Text(s.searchNothing, style: context.text.titleMedium),
                          const SizedBox(height: Space.xs),
                          Text(s.searchNothingHint, textAlign: TextAlign.center, style: context.text.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }
                return CustomScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.lg, Space.md),
                        child: Row(
                          children: [
                            Expanded(child: Text(s.searchFound(found.length), style: context.text.bodyMedium)),
                            AppChip(
                              label: sortLabel(s, _sort),
                              icon: Icons.swap_vert_rounded,
                              selected: false,
                              onTap: () async {
                                final v = await showSortSheet(context, _sort);
                                if (v != null) setState(() => _sort = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    ProductGrid(products: found),
                    const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
                  ],
                );
              },
            ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.history, required this.onPick, required this.onClear});
  final List<String> history;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Space.gutter),
        child: Text(s.searchStartHint, style: context.text.bodyMedium),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.sm, 0),
          child: Row(
            children: [
              Expanded(child: Text(s.searchRecent, style: context.text.titleMedium)),
              TextButton(onPressed: onClear, child: Text(s.clear)),
            ],
          ),
        ),
        for (final h in history)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            leading: Icon(Icons.history_rounded, color: c.textTertiary),
            title: Text(h, style: context.text.bodyLarge),
            trailing: Icon(Icons.north_west_rounded, size: 18, color: c.textTertiary),
            onTap: () => onPick(h),
          ),
      ],
    );
  }
}
