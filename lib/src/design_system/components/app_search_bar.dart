import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search products, brands, or tags',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final isActive = _focusNode.hasFocus || hasText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: theme.brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainer,
        border: Border.all(
          color: isActive ? colorScheme.secondary : colorScheme.outlineVariant,
          width: isActive ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? colorScheme.secondary.withValues(alpha: 0.24)
                : colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: isActive ? 20 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? colorScheme.secondary.withValues(alpha: 0.18)
                  : colorScheme.surfaceContainerHigh,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 21,
              color: isActive ? colorScheme.secondary : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: hasText
                ? IconButton(
                    key: const ValueKey<String>('clear-search'),
                    tooltip: 'Clear search',
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                      _focusNode.requestFocus();
                    },
                  )
                : const SizedBox(
                    key: ValueKey<String>('empty-search-slot'),
                    width: 48,
                  ),
          ),
        ],
      ),
    );
  }
}
