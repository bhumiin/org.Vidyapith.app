import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// ShadCN-style Alert component
class ShadAlert extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? icon;
  final ShadAlertVariant variant;
  final Widget? action;
  final VoidCallback? onClose;

  const ShadAlert({
    super.key,
    this.title,
    this.description,
    this.icon,
    this.variant = ShadAlertVariant.default_,
    this.action,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
        border: Border.all(
          color: _getBorderColor(isDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null || _getDefaultIcon() != null) ...[
            _getIconWidget(isDark),
            const SizedBox(width: ShadCNTheme.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) _buildTitle(theme, isDark),
                if (title != null && description != null)
                  const SizedBox(height: ShadCNTheme.space2),
                if (description != null) _buildDescription(theme, isDark),
                if (action != null) ...[
                  const SizedBox(height: ShadCNTheme.space3),
                  action!,
                ],
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: ShadCNTheme.space3),
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                size: 20,
                color: _getTextColor(isDark),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getIconWidget(bool isDark) {
    final iconData = icon != null ? null : _getDefaultIcon();
    final iconColor = _getIconColor(isDark);

    if (icon != null) {
      return icon!;
    }

    if (iconData != null) {
      return Icon(
        iconData,
        size: 20,
        color: iconColor,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTitle(ThemeData theme, bool isDark) {
    return Text(
      title!,
      style: theme.textTheme.titleSmall?.copyWith(
        color: _getTextColor(isDark),
        fontWeight: ShadCNTheme.fontSemibold,
      ),
    );
  }

  Widget _buildDescription(ThemeData theme, bool isDark) {
    return Text(
      description!,
      style: theme.textTheme.bodySmall?.copyWith(
        color: _getTextColor(isDark),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    switch (variant) {
      case ShadAlertVariant.default_:
        return isDark ? ShadCNTheme.darkBackground : ShadCNTheme.background;
      case ShadAlertVariant.destructive:
        return isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
      case ShadAlertVariant.warning:
        return isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFFBEB);
      case ShadAlertVariant.success:
        return isDark ? const Color(0xFF14532D) : const Color(0xFFF0FDF4);
    }
  }

  Color _getBorderColor(bool isDark) {
    switch (variant) {
      case ShadAlertVariant.default_:
        return isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border;
      case ShadAlertVariant.destructive:
        return isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
      case ShadAlertVariant.warning:
        return isDark ? const Color(0xFF9A3412) : const Color(0xFFFED7AA);
      case ShadAlertVariant.success:
        return isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0);
    }
  }

  Color _getTextColor(bool isDark) {
    switch (variant) {
      case ShadAlertVariant.default_:
        return isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground;
      case ShadAlertVariant.destructive:
        return isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
      case ShadAlertVariant.warning:
        return isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412);
      case ShadAlertVariant.success:
        return isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
    }
  }

  Color _getIconColor(bool isDark) {
    switch (variant) {
      case ShadAlertVariant.default_:
        return isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground;
      case ShadAlertVariant.destructive:
        return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
      case ShadAlertVariant.warning:
        return isDark ? const Color(0xFFFDBA74) : const Color(0xFFD97706);
      case ShadAlertVariant.success:
        return isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);
    }
  }

  IconData? _getDefaultIcon() {
    switch (variant) {
      case ShadAlertVariant.default_:
        return Icons.info_outline;
      case ShadAlertVariant.destructive:
        return Icons.error_outline;
      case ShadAlertVariant.warning:
        return Icons.warning_outlined;
      case ShadAlertVariant.success:
        return Icons.check_circle_outline;
    }
  }
}

enum ShadAlertVariant {
  default_,
  destructive,
  warning,
  success,
}

/// ShadCN-style Toast component
class ShadToast extends StatelessWidget {
  final String title;
  final String? description;
  final ShadAlertVariant variant;
  final Widget? action;
  final Duration? duration;
  final VoidCallback? onClose;

  const ShadToast({
    super.key,
    required this.title,
    this.description,
    this.variant = ShadAlertVariant.default_,
    this.action,
    this.duration,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ShadAlert(
      title: title,
      description: description,
      variant: variant,
      action: action,
      onClose: onClose,
    );
  }
}

/// ShadCN-style Toast Service
class ShadToastService {
  static void show(
    BuildContext context, {
    required String title,
    String? description,
    ShadAlertVariant variant = ShadAlertVariant.default_,
    Widget? action,
    Duration? duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + ShadCNTheme.space4,
        left: ShadCNTheme.space4,
        right: ShadCNTheme.space4,
        child: Material(
          color: Colors.transparent,
          child: ShadToast(
            title: title,
            description: description,
            variant: variant,
            action: action,
            onClose: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after duration
    Future.delayed(duration ?? const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
