import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// ShadCN-style Button component
class ShadButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ShadButtonVariant variant;
  final ShadButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;

  const ShadButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ShadButtonVariant.default_,
    this.size = ShadButtonSize.default_,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: _buildButton(context, isDark),
    );
  }

  Widget _buildButton(BuildContext context, bool isDark) {
    switch (variant) {
      case ShadButtonVariant.default_:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary,
            foregroundColor: isDark ? ShadCNTheme.darkPrimaryForeground : ShadCNTheme.primaryForeground,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShadCNTheme.radius),
            ),
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
          ),
          child: _buildChild(),
        );

      case ShadButtonVariant.destructive:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive,
            foregroundColor: isDark ? ShadCNTheme.darkDestructiveForeground : ShadCNTheme.destructiveForeground,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShadCNTheme.radius),
            ),
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
          ),
          child: _buildChild(),
        );

      case ShadButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary,
            side: BorderSide(
              color: isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShadCNTheme.radius),
            ),
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
          ),
          child: _buildChild(),
        );

      case ShadButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? ShadCNTheme.darkSecondary : ShadCNTheme.secondary,
            foregroundColor: isDark ? ShadCNTheme.darkSecondaryForeground : ShadCNTheme.secondaryForeground,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShadCNTheme.radius),
            ),
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
          ),
          child: _buildChild(),
        );

      case ShadButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShadCNTheme.radius),
            ),
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
          ),
          child: _buildChild(),
        );

      case ShadButtonVariant.link:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary,
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
          ),
          child: _buildChild(),
        );
    }
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ShadButtonVariant.default_ || variant == ShadButtonVariant.destructive
                ? Colors.white
                : Colors.grey[600]!,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: ShadCNTheme.space2),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ShadButtonSize.sm:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space3,
          vertical: ShadCNTheme.space1,
        );
      case ShadButtonSize.default_:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space4,
          vertical: ShadCNTheme.space2,
        );
      case ShadButtonSize.lg:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space8,
          vertical: ShadCNTheme.space3,
        );
      case ShadButtonSize.icon:
        return const EdgeInsets.all(ShadCNTheme.space2);
    }
  }

  Size _getMinimumSize() {
    switch (size) {
      case ShadButtonSize.sm:
        return const Size(0, 32);
      case ShadButtonSize.default_:
        return const Size(0, 40);
      case ShadButtonSize.lg:
        return const Size(0, 48);
      case ShadButtonSize.icon:
        return const Size(40, 40);
    }
  }

  double _getIconSize() {
    switch (size) {
      case ShadButtonSize.sm:
        return 16;
      case ShadButtonSize.default_:
        return 20;
      case ShadButtonSize.lg:
        return 24;
      case ShadButtonSize.icon:
        return 20;
    }
  }
}

enum ShadButtonVariant {
  default_,
  destructive,
  outline,
  secondary,
  ghost,
  link,
}

enum ShadButtonSize {
  sm,
  default_,
  lg,
  icon,
}

/// Icon-only button variant
class ShadIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ShadButtonVariant variant;
  final ShadButtonSize size;

  const ShadIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = ShadButtonVariant.default_,
    this.size = ShadButtonSize.default_,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton(
      text: '',
      onPressed: onPressed,
      variant: variant,
      size: ShadButtonSize.icon,
      icon: Icon(icon, size: _getIconSize()),
    );
  }

  double _getIconSize() {
    switch (size) {
      case ShadButtonSize.sm:
        return 16;
      case ShadButtonSize.default_:
        return 20;
      case ShadButtonSize.lg:
        return 24;
      case ShadButtonSize.icon:
        return 20;
    }
  }
}
