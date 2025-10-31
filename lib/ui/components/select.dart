import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// ShadCN-style Select component
class ShadSelect<T> extends StatefulWidget {
  final List<ShadSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool fullWidth;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const ShadSelect({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.fullWidth = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<ShadSelect<T>> createState() => _ShadSelectState<T>();
}

class _ShadSelectState<T> extends State<ShadSelect<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null;
    ShadSelectOption<T>? selectedOption;
    if (widget.value != null) {
      try {
        selectedOption = widget.options.firstWhere(
          (option) => option.value == widget.value,
        );
      } catch (e) {
        selectedOption = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) _buildLabel(theme, isDark),
        if (widget.label != null) const SizedBox(height: ShadCNTheme.space2),
        _buildSelect(theme, isDark, hasError, selectedOption),
        if (widget.helperText != null || widget.errorText != null)
          const SizedBox(height: ShadCNTheme.space2),
        if (widget.helperText != null || widget.errorText != null)
          _buildHelperText(theme, isDark),
      ],
    );
  }

  Widget _buildLabel(ThemeData theme, bool isDark) {
    return Text(
      widget.label!,
      style: theme.textTheme.labelMedium?.copyWith(
        color: isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground,
        fontWeight: ShadCNTheme.fontMedium,
      ),
    );
  }

  Widget _buildSelect(ThemeData theme, bool isDark, bool hasError, ShadSelectOption<T>? selectedOption) {
    final borderColor = hasError
        ? (isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive)
        : (isDark ? ShadCNTheme.darkInput : ShadCNTheme.input);

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: InkWell(
        onTap: widget.enabled ? _showSelectDialog : null,
        borderRadius: BorderRadius.circular(ShadCNTheme.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ShadCNTheme.space3,
            vertical: ShadCNTheme.space2,
          ),
          decoration: BoxDecoration(
            color: isDark ? ShadCNTheme.darkBackground : ShadCNTheme.background,
            borderRadius: BorderRadius.circular(ShadCNTheme.radius),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                widget.prefixIcon!,
                const SizedBox(width: ShadCNTheme.space2),
              ],
              Expanded(
                child: Text(
                  selectedOption?.label.isNotEmpty == true
                      ? selectedOption!.label
                      : (widget.placeholder ?? 'Select an option'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selectedOption?.label.isNotEmpty == true
                        ? (isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground)
                        : (isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground),
                  ),
                ),
              ),
              if (widget.suffixIcon != null)
                widget.suffixIcon!
              else
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground,
                ),
            ],
          ),
        ),
      ),
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

  void _showSelectDialog() {
    showDialog(
      context: context,
      builder: (context) => _SelectDialog<T>(
        options: widget.options,
        value: widget.value,
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _SelectDialog<T> extends StatelessWidget {
  final List<ShadSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;

  const _SelectDialog({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? ShadCNTheme.darkCard : ShadCNTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option.value == value;

            return InkWell(
              onTap: () {
                onChanged?.call(option.value);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ShadCNTheme.space4,
                  vertical: ShadCNTheme.space3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? ShadCNTheme.darkAccent : ShadCNTheme.accent)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? (isDark ? ShadCNTheme.darkAccentForeground : ShadCNTheme.accentForeground)
                              : (isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 20,
                        color: isDark ? ShadCNTheme.darkAccentForeground : ShadCNTheme.accentForeground,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ShadSelectOption<T> {
  final T value;
  final String label;

  const ShadSelectOption({
    required this.value,
    required this.label,
  });
}
