import 'package:flutter/material.dart';

import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import 'class_detail_screen.dart';
import '../components/branded_app_bar.dart';

/// Classes Screen - This screen displays an overview of all class types offered at Vidyapith.
/// 
/// What this screen does:
/// - Shows an introduction explaining that Vidyapith offers classes for all ages
/// - Displays three main class categories as clickable cards:
///   - Curricular Classes (Kindergarten through 12th Grade)
///   - Music Classes (Vocal and Tabla)
///   - Summer Camp Classes
/// - Each card shows a thumbnail image and the class category name
/// 
/// How users interact with it:
/// - Tap any class category card to see detailed information about that class type
/// - On larger screens (tablets), cards are displayed side-by-side
/// - On smaller screens (phones), cards are stacked vertically
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  /// List of all class categories available at Vidyapith.
  /// Each entry contains the class name and a thumbnail image URL from the website.
  static const List<_ClassInfo> _classInfos = [
    _ClassInfo(
      title: 'Curricular Classes',
      imageUrl:
          'https://www.vidyapith.org/uploads/5/2/1/3/52135817/published/8845720.jpg?1584063149',
    ),
    _ClassInfo(
      title: 'Music Classes',
      imageUrl:
          'https://www.vidyapith.org/uploads/5/2/1/3/52135817/7202589.jpg',
    ),
    _ClassInfo(
      title: 'Summer Camp',
      imageUrl:
          'https://www.vidyapith.org/uploads/5/2/1/3/52135817/__1511582.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: buildBrandedAppBar(
        title: const Text('Classes'),
        backgroundColor: isDark ? theme.colorScheme.surface : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ShadCNTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'As an Academy Of Indian Philosphy and Culture, Vivekananda Vidyapith conducts classes for all ages throughout the year.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: ShadCNTheme.fontSemibold,
                color: isDark
                    ? ShadCNTheme.darkCardForeground
                    : ShadCNTheme.cardForeground,
              ),
            ),
            const SizedBox(height: ShadCNTheme.space6),
            LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                final bool isWide = maxWidth >= 768;
                final double horizontalSpacing = ShadCNTheme.space3;
                final double itemWidth = isWide
                    ? (maxWidth - (horizontalSpacing * 2)) / 3
                    : maxWidth;

                return Wrap(
                  spacing: horizontalSpacing,
                  runSpacing: horizontalSpacing,
                  children: _classInfos.map((info) {
                    final double cardWidth = isWide ? itemWidth : maxWidth;
                    return SizedBox(
                      width: cardWidth,
                      child: _ClassThumbnailCard(info: info),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class that stores information about a class category.
/// Contains the class name (e.g., "Curricular Classes") and the URL of its thumbnail image.
class _ClassInfo {
  /// The name of the class category (e.g., "Curricular Classes", "Music Classes").
  final String title;
  
  /// The web address (URL) of the thumbnail image for this class category.
  final String imageUrl;

  const _ClassInfo({required this.title, required this.imageUrl});
}

/// Widget that displays a clickable card for a class category.
/// Shows the class thumbnail image and title. When tapped, opens the detailed class information screen.
class _ClassThumbnailCard extends StatelessWidget {
  /// Information about the class category to display (name and image URL).
  final _ClassInfo info;

  const _ClassThumbnailCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      padding: EdgeInsets.zero,
      // When tapped, opens the detailed class information screen for this class category
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(title: info.title),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(ShadCNTheme.radiusLg),
              topRight: Radius.circular(ShadCNTheme.radiusLg),
            ),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                info.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                    color: isDark
                        ? ShadCNTheme.darkMuted
                        : ShadCNTheme.muted,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color:
                        isDark ? ShadCNTheme.darkMuted : ShadCNTheme.muted,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: isDark
                          ? ShadCNTheme.darkMutedForeground
                          : ShadCNTheme.mutedForeground,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(ShadCNTheme.space4),
            child: Text(
              info.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: ShadCNTheme.fontSemibold,
                color: isDark
                    ? ShadCNTheme.darkCardForeground
                    : ShadCNTheme.cardForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

