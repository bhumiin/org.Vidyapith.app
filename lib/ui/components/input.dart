import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/shadcn_theme.dart';

/// A customizable text input field styled like ShadCN UI.
/// 
/// Supports labels, placeholders, helper text, error messages, icons,
/// validation, and automatic focus state management. Adapts to light/dark themes.
/// 
/// Example usage:
/// ```dart
/// ShadInput(
///   label: 'Email',
///   placeholder: 'Enter your email',
///   controller: emailController,
///   keyboardType: TextInputType.emailAddress,
///   errorText: 'Please enter a valid email',
/// )
/// ```
class ShadInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final ShadInputSize size;
  final bool fullWidth;

  const ShadInput({
    super.key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.size = ShadInputSize.default_,
    this.fullWidth = false,
  });

  @override
  State<ShadInput> createState() => _ShadInputState();
}

class _ShadInputState extends State<ShadInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  /// Updates the focus state when the input gains or loses focus
  /// This is used to change the border color when focused
  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) _buildLabel(theme, isDark),
          if (widget.label != null) const SizedBox(height: ShadCNTheme.space2),
          _buildInput(theme, isDark),
          if (widget.helperText != null || widget.errorText != null)
            const SizedBox(height: ShadCNTheme.space2),
          if (widget.helperText != null || widget.errorText != null)
            _buildHelperText(theme, isDark),
        ],
      ),
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

  /// Builds the actual text input field with appropriate styling
  Widget _buildInput(ThemeData theme, bool isDark) {
    final hasError = widget.errorText != null;
    // Border color changes based on state: error (red) > focused (ring color) > default (input color)
    final borderColor = hasError
        ? (isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive)
        : _isFocused
            ? (isDark ? ShadCNTheme.darkRing : ShadCNTheme.ring) // Highlight when focused
            : (isDark ? ShadCNTheme.darkInput : ShadCNTheme.input); // Default border

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ShadCNTheme.radius),
        border: Border.all(
          color: borderColor,
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        focusNode: _focusNode,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground,
          ),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: _getContentPadding(),
          counterText: '',
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

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case ShadInputSize.sm:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space3,
          vertical: ShadCNTheme.space1,
        );
      case ShadInputSize.default_:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space3,
          vertical: ShadCNTheme.space2,
        );
      case ShadInputSize.lg:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space4,
          vertical: ShadCNTheme.space3,
        );
    }
  }
}

enum ShadInputSize {
  sm,
  default_,
  lg,
}

/// A multi-line text input field (textarea) styled like ShadCN UI.
/// 
/// This is essentially a ShadInput configured for multi-line text entry.
/// Perfect for longer text inputs like comments, descriptions, or messages.
/// 
/// Example usage:
/// ```dart
/// ShadTextarea(
///   label: 'Message',
///   placeholder: 'Enter your message...',
///   minLines: 3,
///   maxLines: 6,
/// )
/// ```
class ShadTextarea extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool fullWidth;

  const ShadTextarea({
    super.key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 4,
    this.minLines = 3,
    this.maxLength,
    this.inputFormatters,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShadInput(
      label: label,
      placeholder: placeholder,
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      initialValue: initialValue,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      fullWidth: fullWidth,
    );
  }
}
