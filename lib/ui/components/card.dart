import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// A card component styled like ShadCN UI.
/// 
/// Cards are used to group related content. They have rounded corners,
/// borders, shadows, and support optional tap actions.
/// 
/// Example usage:
/// ```dart
/// ShadCard(
///   child: Text('Card content'),
///   padding: EdgeInsets.all(16),
///   onTap: () => navigateToDetails(),
/// )
/// ```
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

/// A header section for cards, typically containing the title.
/// 
/// Provides consistent padding and spacing for card headers.
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

/// A title widget for cards with consistent styling.
/// 
/// Automatically adapts to light/dark themes.
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

/// A description/subtitle widget for cards with muted text styling.
/// 
/// Typically used below the card title for additional context.
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

/// The main content area of a card.
/// 
/// Provides consistent padding for card body content.
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

/// A footer section for cards, typically containing actions or additional info.
/// 
/// Provides consistent padding and spacing for card footers.
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

/// A complete card widget with all sections pre-configured.
/// 
/// This is a convenience widget that combines header, content, and footer
/// into a single card. Perfect for consistent card layouts.
/// 
/// Example usage:
/// ```dart
/// ShadCardComplete(
///   title: 'Event Title',
///   description: 'Event description',
///   content: Text('Event details...'),
///   footer: ShadButton(text: 'Register'),
/// )
/// ```
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
