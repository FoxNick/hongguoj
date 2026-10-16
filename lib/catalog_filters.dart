import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'app_layout.dart';
import 'models.dart';
import 'remote_widgets.dart';

class CatalogFilters extends StatefulWidget {
  const CatalogFilters({
    super.key,
    required this.categories,
    required this.category,
    required this.onCategory,
    required this.onRetry,
    this.error,
    this.trailing,
    this.followFocus = false,
  });

  final List<CatalogCategory> categories;
  final String category;
  final String? error;
  final ValueChanged<String> onCategory;
  final VoidCallback onRetry;
  final Widget? trailing;

  /// 电视遥控：在同一排分类之间横向移动时跟随切换（带防抖），不必再按确定。
  /// 焦点从别处（例如搜索框按方向键）扫过某个分类时不跟随。
  final bool followFocus;

  @override
  State<CatalogFilters> createState() => _CatalogFiltersState();
}

class _CatalogFiltersState extends State<CatalogFilters> {
  final _anchors = <String, GlobalKey>{};
  final _rowFocus = FocusNode(debugLabel: 'catalog-categories');
  Timer? _follow;
  String? _previousFocus;

  @override
  void initState() {
    super.initState();
    _rowFocus.addListener(_rowFocusChanged);
  }

  void _rowFocusChanged() {
    if (_rowFocus.hasFocus) return;
    _previousFocus = null;
    _follow?.cancel();
  }

  @override
  void dispose() {
    _follow?.cancel();
    _rowFocus.removeListener(_rowFocusChanged);
    _rowFocus.dispose();
    super.dispose();
  }

  void _focusCategory(String id) {
    final previous = _previousFocus;
    _previousFocus = id;
    if (!widget.followFocus || id == widget.category) return;
    if (previous == null || previous == id) return;
    _follow?.cancel();
    _follow = Timer(const Duration(milliseconds: 100), () {
      if (mounted) widget.onCategory(id);
    });
  }

  void _selectCategory(String id) {
    _follow?.cancel();
    widget.onCategory(id);
  }

  @override
  void didUpdateWidget(covariant CatalogFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _follow?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final anchor = _anchors[widget.category]?.currentContext;
        if (mounted && anchor != null) {
          Scrollable.ensureVisible(
            anchor,
            alignment: .4,
            duration: const Duration(milliseconds: 180),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final television = AppLayout.isTelevision(context);
    return SizedBox(
      height: television
          ? 64
          : max(52, MediaQuery.textScalerOf(context).scale(14) + 28),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              focusNode: _rowFocus,
              canRequestFocus: false,
              child: SingleChildScrollView(
                key: const ValueKey('catalog-categories'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final entry in widget.categories)
                      Padding(
                        key: _anchors.putIfAbsent(entry.id, GlobalKey.new),
                        padding: const EdgeInsets.only(right: 6),
                        child: television
                            ? RemoteButton(
                                key: ValueKey('category-${entry.id}'),
                                label: entry.name,
                                selected: entry.id == widget.category,
                                selectedBackground: false,
                                onFocus: () => _focusCategory(entry.id),
                                onPressed: () => _selectCategory(entry.id),
                              )
                            : ChoiceChip(
                                key: ValueKey('category-${entry.id}'),
                                label: Text(entry.name),
                                selected: entry.id == widget.category,
                                showCheckmark: false,
                                onSelected: (_) => _selectCategory(entry.id),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.error != null)
            IconButton(
              tooltip: widget.error,
              onPressed: widget.onRetry,
              icon: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}
