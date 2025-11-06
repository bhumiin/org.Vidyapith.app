import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// A badge component styled like ShadCN UI.
/// 
/// Badges are small labels used to display status, counts, or categories.
/// They support multiple variants (default, secondary, destructive, outline)
/// and sizes (sm, default, lg).
/// 
/// Example usage:
/// ```dart
/// ShadBadge(
///   text: 'New',
///   variant: ShadBadgeVariant.default_,
///   size: ShadBadgeSize.default_,
///   icon: Icon(Icons.star),
/// )
/// ```
class ShadBadge extends StatelessWidget {
  final String text;
  final ShadBadgeVariant variant;
  final ShadBadgeSize size;
  final Widget? icon;

  const ShadBadge({
    super.key,
    required this.text,
    this.variant = ShadBadgeVariant.default_,
    this.size = ShadBadgeSize.default_,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(ShadCNTheme.radiusFull),
        border: _getBorder(isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: ShadCNTheme.space1),
          ],
          Text(
            text,
            style: _getTextStyle(theme, isDark),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    switch (variant) {
      case ShadBadgeVariant.default_:
        return isDark ? ShadCNTheme.darkPrimary : ShadCNTheme.primary;
      case ShadBadgeVariant.secondary:
        return isDark ? ShadCNTheme.darkSecondary : ShadCNTheme.secondary;
      case ShadBadgeVariant.destructive:
        return isDark ? ShadCNTheme.darkDestructive : ShadCNTheme.destructive;
      case ShadBadgeVariant.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor(bool isDark) {
    switch (variant) {
      case ShadBadgeVariant.default_:
        return isDark ? ShadCNTheme.darkPrimaryForeground : ShadCNTheme.primaryForeground;
      case ShadBadgeVariant.secondary:
        return isDark ? ShadCNTheme.darkSecondaryForeground : ShadCNTheme.secondaryForeground;
      case ShadBadgeVariant.destructive:
        return isDark ? ShadCNTheme.darkDestructiveForeground : ShadCNTheme.destructiveForeground;
      case ShadBadgeVariant.outline:
        return isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground;
    }
  }

  Border? _getBorder(bool isDark) {
    if (variant == ShadBadgeVariant.outline) {
      return Border.all(
        color: isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border,
      );
    }
    return null;
  }

  TextStyle _getTextStyle(ThemeData theme, bool isDark) {
    final baseStyle = theme.textTheme.labelSmall?.copyWith(
      color: _getTextColor(isDark),
      fontWeight: ShadCNTheme.fontMedium,
    );

    switch (size) {
      case ShadBadgeSize.sm:
        return baseStyle?.copyWith(fontSize: ShadCNTheme.textXs) ?? TextStyle(fontSize: ShadCNTheme.textXs);
      case ShadBadgeSize.default_:
        return baseStyle?.copyWith(fontSize: ShadCNTheme.textSm) ?? TextStyle(fontSize: ShadCNTheme.textSm);
      case ShadBadgeSize.lg:
        return baseStyle?.copyWith(fontSize: ShadCNTheme.textBase) ?? TextStyle(fontSize: ShadCNTheme.textBase);
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ShadBadgeSize.sm:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space2,
          vertical: ShadCNTheme.space1,
        );
      case ShadBadgeSize.default_:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space2,
          vertical: ShadCNTheme.space1,
        );
      case ShadBadgeSize.lg:
        return const EdgeInsets.symmetric(
          horizontal: ShadCNTheme.space3,
          vertical: ShadCNTheme.space2,
        );
    }
  }
}

enum ShadBadgeVariant {
  default_,
  secondary,
  destructive,
  outline,
}

enum ShadBadgeSize {
  sm,
  default_,
  lg,
}
