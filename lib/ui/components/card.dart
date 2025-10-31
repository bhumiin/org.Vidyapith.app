import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// ShadCN-style Card component
class ShadCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const ShadCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? ShadCNTheme.darkCard : ShadCNTheme.card,
        borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
        border: Border.all(
          color: isDark ? ShadCNTheme.darkBorder : ShadCNTheme.border,
        ),
        boxShadow: ShadCNTheme.shadowSm,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(ShadCNTheme.space6),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// ShadCN-style Card Header component
class ShadCardHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ShadCardHeader({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(
        left: ShadCNTheme.space6,
        right: ShadCNTheme.space6,
        top: ShadCNTheme.space6,
        bottom: ShadCNTheme.space3,
      ),
      child: child,
    );
  }
}

/// ShadCN-style Card Title component
class ShadCardTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ShadCardTitle({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      text,
      style: style ?? theme.textTheme.titleLarge?.copyWith(
        color: isDark ? ShadCNTheme.darkCardForeground : ShadCNTheme.cardForeground,
        fontWeight: ShadCNTheme.fontSemibold,
      ),
    );
  }
}

/// ShadCN-style Card Description component
class ShadCardDescription extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ShadCardDescription({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      text,
      style: style ?? theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? ShadCNTheme.darkMutedForeground : ShadCNTheme.mutedForeground,
      ),
    );
  }
}

/// ShadCN-style Card Content component
class ShadCardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ShadCardContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: ShadCNTheme.space6,
        vertical: ShadCNTheme.space3,
      ),
      child: child,
    );
  }
}

/// ShadCN-style Card Footer component
class ShadCardFooter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ShadCardFooter({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(
        left: ShadCNTheme.space6,
        right: ShadCNTheme.space6,
        top: ShadCNTheme.space3,
        bottom: ShadCNTheme.space6,
      ),
      child: child,
    );
  }
}

/// Complete ShadCN-style Card with all sections
class ShadCardComplete extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? content;
  final Widget? footer;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const ShadCardComplete({
    super.key,
    this.title,
    this.description,
    this.content,
    this.footer,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      onTap: onTap,
      margin: margin,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || description != null)
            ShadCardHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ShadCardTitle(text: title!),
                  if (title != null && description != null)
                    const SizedBox(height: ShadCNTheme.space2),
                  if (description != null) ShadCardDescription(text: description!),
                ],
              ),
            ),
          if (content != null) ShadCardContent(child: content!),
          if (footer != null) ShadCardFooter(child: footer!),
        ],
      ),
    );
  }
}
