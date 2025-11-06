import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// A radio button component styled like ShadCN UI.
/// 
/// Radio buttons allow users to select exactly one option from a group.
/// Supports labels, helper text, error messages, and multiple sizes.
/// 
/// Example usage:
/// ```dart
/// ShadRadio<String>(
///   value: 'option1',
///   groupValue: selectedOption,
///   onChanged: (value) => setState(() => selectedOption = value),
///   label: 'Option 1',
/// )
/// ```
class ShadRadio<T> extends StatefulWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ShadRadioSize size;

  const ShadRadio({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.size = ShadRadioSize.default_,
  });

  @override
  State<ShadRadio<T>> createState() => _ShadRadioState<T>();
}

class _ShadRadioState<T> extends State<ShadRadio<T>> {
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
              child: Radio<T>(
                value: widget.value,
                groupValue: widget.groupValue,
                onChanged: widget.enabled ? widget.onChanged : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground;
                  }
                  if (states.contains(WidgetState.selected)) {
                    return isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary;
                  }
                  return hasError
                      ? (isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive)
                      : (isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border);
                }),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(width: ShadCNTheme.space2),
              Expanded(
                child: GestureDetector(
                  onTap: widget.enabled ? () => widget.onChanged?.call(widget.value) : null,
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
      case ShadRadioSize.sm:
        return 16;
      case ShadRadioSize.default_:
        return 20;
      case ShadRadioSize.lg:
        return 24;
    }
  }
}

enum ShadRadioSize {
  sm,
  default_,
  lg,
}

/// A group of radio buttons that allows single selection.
/// 
/// This widget manages a list of radio buttons and tracks which one is selected.
/// Supports horizontal and vertical layouts.
/// 
/// Example usage:
/// ```dart
/// ShadRadioGroup<String>(
///   label: 'Choose your plan',
///   options: [
///     ShadRadioOption(value: 'basic', label: 'Basic'),
///     ShadRadioOption(value: 'premium', label: 'Premium'),
///   ],
///   value: selectedPlan,
///   onChanged: (value) => setState(() => selectedPlan = value),
/// )
/// ```
class ShadRadioGroup<T> extends StatefulWidget {
  final List<ShadRadioOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ShadRadioSize size;
  final Axis direction;

  const ShadRadioGroup({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.size = ShadRadioSize.default_,
    this.direction = Axis.vertical,
  });

  @override
  State<ShadRadioGroup<T>> createState() => _ShadRadioGroupState<T>();
}

class _ShadRadioGroupState<T> extends State<ShadRadioGroup<T>> {
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
        _buildRadios(),
        if (widget.helperText != null || widget.errorText != null)
          const SizedBox(height: ShadCNTheme.space2),
        if (widget.helperText != null || widget.errorText != null)
          _buildHelperText(theme, isDark),
      ],
    );
  }

  Widget _buildRadios() {
    if (widget.direction == Axis.horizontal) {
      return Wrap(
        spacing: ShadCNTheme.space6,
        runSpacing: ShadCNTheme.space4,
        children: widget.options.map((option) => _buildRadio(option)).toList(),
      );
    } else {
      return Column(
        children: widget.options.map((option) => _buildRadio(option)).toList(),
      );
    }
  }

  Widget _buildRadio(ShadRadioOption<T> option) {
    return ShadRadio<T>(
      value: option.value,
      groupValue: widget.value,
      onChanged: widget.enabled ? widget.onChanged : null,
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

/// Represents an option in a ShadRadioGroup.
/// 
/// Each option has a value and a label.
class ShadRadioOption<T> {
  /// The value of the option (used to track selection)
  final T value;
  /// The text displayed next to the radio button
  final String label;

  const ShadRadioOption({
    required this.value,
    required this.label,
  });
}
