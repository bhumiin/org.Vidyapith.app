import 'package:flutter/material.dart';
import '../theme/shadcn_theme.dart';

/// A customizable container component styled like ShadCN UI.
/// 
/// This is a flexible container widget with support for padding, margins,
/// borders, shadows, and tap actions. Perfect for creating custom layouts.
/// 
/// Example usage:
/// ```dart
/// ShadContainer(
///   child: Text('Content'),
///   padding: EdgeInsets.all(16),
///   borderRadius: BorderRadius.circular(8),
///   onTap: () => handleTap(),
/// )
/// ```
class ShadContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final VoidCallback? onTap;

  const ShadContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
    this.alignment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? ShadCNTheme.darkBackground : ShadCNTheme.background),
        borderRadius: borderRadius ?? BorderRadius.circular(ShadCNTheme.radius),
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(ShadCNTheme.radius),
        child: container,
      );
    }

    return container;
  }
}

/// A section component for organizing content with optional headers and footers.
/// 
/// Sections are useful for grouping related content together with consistent
/// spacing and optional titles/descriptions.
/// 
/// Example usage:
/// ```dart
/// ShadSection(
///   title: 'About Us',
///   description: 'Learn more about our organization',
///   child: Text('Section content...'),
/// )
/// ```
class ShadSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String? title;
  final String? description;
  final Widget? header;
  final Widget? footer;

  const ShadSection({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.title,
    this.description,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) header!,
          if (title != null || description != null)
            _buildHeader(context),
          if (title != null || description != null)
            const SizedBox(height: ShadCNTheme.space6),
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
          if (footer != null) ...[
            const SizedBox(height: ShadCNTheme.space6),
            footer!,
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? ShadCNTheme.darkForeground : ShadCNTheme.foreground,
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
    );
  }
}

/// A flexible layout component that arranges children in a row or column.
/// 
/// This widget provides easy spacing between children and consistent styling.
/// 
/// Example usage:
/// ```dart
/// ShadFlex(
///   direction: Axis.horizontal,
///   spacing: 16,
///   children: [Widget1(), Widget2(), Widget3()],
/// )
/// ```
class ShadFlex extends StatelessWidget {
  final List<Widget> children;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ShadFlex({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget flex = Flex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: _buildChildren(),
    );

    if (padding != null || margin != null) {
      flex = Container(
        padding: padding,
        margin: margin,
        child: flex,
      );
    }

    return flex;
  }

  List<Widget> _buildChildren() {
    if (spacing == null || children.length <= 1) {
      return children;
    }

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        if (direction == Axis.horizontal) {
          spacedChildren.add(SizedBox(width: spacing!));
        } else {
          spacedChildren.add(SizedBox(height: spacing!));
        }
      }
    }
    return spacedChildren;
  }
}

/// A grid layout component for displaying items in a grid.
/// 
/// Perfect for creating card grids, image galleries, or any grid-based layouts.
/// 
/// Example usage:
/// ```dart
/// ShadGrid(
///   crossAxisCount: 2,
///   children: [Card1(), Card2(), Card3(), Card4()],
/// )
/// ```
class ShadGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ShadGrid({
    super.key,
    required this.children,
    required this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget grid = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing ?? ShadCNTheme.space4,
        mainAxisSpacing: mainAxisSpacing ?? ShadCNTheme.space4,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );

    if (padding != null || margin != null) {
      grid = Container(
        padding: padding,
        margin: margin,
        child: grid,
      );
    }

    return grid;
  }
}

/// A stack component for overlaying widgets on top of each other.
/// 
/// Useful for creating layered layouts, badges on avatars, or floating elements.
/// 
/// Example usage:
/// ```dart
/// ShadStack(
///   children: [
///     BackgroundImage(),
///     PositionedText(),
///   ],
/// )
/// ```
class ShadStack extends StatelessWidget {
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final StackFit fit;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ShadStack({
    super.key,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget stack = Stack(
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
      children: children,
    );

    if (padding != null || margin != null) {
      stack = Container(
        padding: padding,
        margin: margin,
        child: stack,
      );
    }

    return stack;
  }
}
