import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// ShadCN-style Checkbox component
class ShadCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool tristate;
  final ShadCheckboxSize size;

  const ShadCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.tristate = false,
    this.size = ShadCheckboxSize.default_,
  });

  @override
  State<ShadCheckbox> createState() => _ShadCheckboxState();
}

class _ShadCheckboxState extends State<ShadCheckbox> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: _getSize(),
              height: _getSize(),
              child: Checkbox(
                value: widget.value,
                onChanged: widget.enabled ? widget.onChanged : null,
                tristate: widget.tristate,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: hasError
                      ? (isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive)
                      : (isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ShadCNTheme.radiusSm),
                ),
                activeColor: isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary,
                checkColor: isDark ? ShadCNTheme.darkPrimaryForeground : ShadCNTheme.primaryForeground,
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(width: ShadCNTheme.space2),
              Expanded(
                child: GestureDetector(
                  onTap: widget.enabled ? () => widget.onChanged?.call(!widget.value) : null,
                  child: Text(
                    widget.label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.enabled
                          ? (isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground)
                          : (isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.helperText != null || widget.errorText != null)
          const SizedBox(height: ShadCNTheme.space2),
        if (widget.helperText != null || widget.errorText != null)
          _buildHelperText(theme, isDark),
      ],
    );
  }

  Widget _buildHelperText(ThemeData theme, bool isDark) {
    final hasError = widget.errorText != null;
    final text = hasError ? widget.errorText! : widget.helperText!;
    final color = hasError
        ? (isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive)
        : (isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground);

    return Padding(
      padding: EdgeInsets.only(left: _getSize() + ShadCNTheme.space2),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: ShadCNTheme.textXs,
        ),
      ),
    );
  }

  double _getSize() {
    switch (widget.size) {
      case ShadCheckboxSize.sm:
        return 16;
      case ShadCheckboxSize.default_:
        return 20;
      case ShadCheckboxSize.lg:
        return 24;
    }
  }
}

enum ShadCheckboxSize {
  sm,
  default_,
  lg,
}

/// ShadCN-style Checkbox Group component
class ShadCheckboxGroup extends StatefulWidget {
  final List<ShadCheckboxOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>>? onChanged;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ShadCheckboxSize size;
  final Axis direction;

  const ShadCheckboxGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    this.onChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.size = ShadCheckboxSize.default_,
    this.direction = Axis.vertical,
  });

  @override
  State<ShadCheckboxGroup> createState() => _ShadCheckboxGroupState();
}

class _ShadCheckboxGroupState extends State<ShadCheckboxGroup> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground,
              fontWeight: ShadCNTheme.fontMedium,
            ),
          ),
        if (widget.label != null) const SizedBox(height: ShadCNTheme.space3),
        _buildCheckboxes(),
        if (widget.helperText != null || widget.errorText != null)
          const SizedBox(height: ShadCNTheme.space2),
        if (widget.helperText != null || widget.errorText != null)
          _buildHelperText(theme, isDark),
      ],
    );
  }

  Widget _buildCheckboxes() {
    if (widget.direction == Axis.horizontal) {
      return Wrap(
        spacing: ShadCNTheme.space6,
        runSpacing: ShadCNTheme.space4,
        children: widget.options.map((option) => _buildCheckbox(option)).toList(),
      );
    } else {
      return Column(
        children: widget.options.map((option) => _buildCheckbox(option)).toList(),
      );
    }
  }

  Widget _buildCheckbox(ShadCheckboxOption option) {
    final isSelected = widget.selectedValues.contains(option.value);

    return ShadCheckbox(
      value: isSelected,
      onChanged: widget.enabled
          ? (value) {
              final newValues = List<String>.from(widget.selectedValues);
              if (value == true) {
                if (!newValues.contains(option.value)) {
                  newValues.add(option.value);
                }
              } else {
                newValues.remove(option.value);
              }
              widget.onChanged?.call(newValues);
            }
          : null,
      label: option.label,
      enabled: widget.enabled,
      size: widget.size,
    );
  }

  Widget _buildHelperText(ThemeData theme, bool isDark) {
    final hasError = widget.errorText != null;
    final text = hasError ? widget.errorText! : widget.helperText!;
    final color = hasError
        ? (isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive)
        : (isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontSize: ShadCNTheme.textXs,
      ),
    );
  }
}

class ShadCheckboxOption {
  final String value;
  final String label;

  const ShadCheckboxOption({
    required this.value,
    required this.label,
  });
}
