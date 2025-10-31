import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';
import 'button.dart';
import 'alert.dart';

/// ShadCN-style Dialog component
class ShadDialog extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? content;
  final List<Widget>? actions;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double? maxWidth;
  final double? maxHeight;

  const ShadDialog({
    super.key,
    this.title,
    this.description,
    this.content,
    this.actions,
    this.showCloseButton = true,
    this.onClose,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navigatorContext = context;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 500,
          maxHeight: maxHeight ?? 600,
        ),
        decoration: BoxDecoration(
          color: isDark ? ShadCNTheme.darkCard : ShadCNTheme.card,
          borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
          border: Border.all(
            color: isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border,
          ),
          boxShadow: ShadCNTheme.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || description != null || showCloseButton)
              _buildHeader(theme, isDark),
            if (content != null) _buildContent(),
            if (actions != null && actions!.isNotEmpty) _buildActions(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(ShadCNTheme.space6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark ? ShadCNTheme.darkCardForeground : ShadCNTheme.cardForeground,
                      fontWeight: ShadCNTheme.fontSemibold,
                    ),
                  ),
                if (title != null && description != null)
                  const SizedBox(height: ShadCNTheme.space2),
                if (description != null)
                  Text(
                    description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (showCloseButton)
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                size: 20,
                color: isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ShadCNTheme.space6),
        child: content!,
      ),
    );
  }

  Widget _buildActions(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(ShadCNTheme.space6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions!
            .map((action) => Padding(
                  padding: const EdgeInsets.only(left: ShadCNTheme.space2),
                  child: action,
                ))
            .toList(),
      ),
    );
  }
}

/// ShadCN-style Alert Dialog component
class ShadAlertDialog extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ShadAlertVariant variant;

  const ShadAlertDialog({
    super.key,
    this.title,
    this.description,
    this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.variant = ShadAlertVariant.default_,
  });

  @override
  Widget build(BuildContext context) {
    final navigatorContext = context;
    return ShadDialog(
      title: title,
      description: description,
      content: content,
      actions: [
        if (cancelText != null)
          ShadButton(
            text: cancelText!,
            variant: ShadButtonVariant.outline,
            onPressed: onCancel,
          ),
        if (confirmText != null)
          ShadButton(
            text: confirmText!,
            variant: variant == ShadAlertVariant.destructive
                ? ShadButtonVariant.destructive
                : ShadButtonVariant.default_,
            onPressed: onConfirm,
          ),
      ],
    );
  }
}

/// ShadCN-style Dialog Service
class ShadDialogService {
  static Future<T?> showDialog<T>({
    required BuildContext context,
    String? title,
    String? description,
    Widget? content,
    List<Widget>? actions,
    bool showCloseButton = true,
    double? maxWidth,
    double? maxHeight,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ShadDialog(
          title: title,
          description: description,
          content: content,
          actions: actions,
          showCloseButton: showCloseButton,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );
  }

  static Future<T?> showAlertDialog<T>({
    required BuildContext context,
    String? title,
    String? description,
    Widget? content,
    String? confirmText = 'Confirm',
    String? cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    ShadAlertVariant variant = ShadAlertVariant.default_,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => ShadAlertDialog(
        title: title,
        description: description,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        variant: variant,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );
  }
}

