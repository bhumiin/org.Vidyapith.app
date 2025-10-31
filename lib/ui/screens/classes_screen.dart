import 'package:flutter/material.dart';

import '../components/card.dart';
import '../theme/shadcn_theme.dart';
import 'class_detail_screen.dart';
import '../components/branded_app_bar.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

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

class _ClassInfo {
  final String title;
  final String imageUrl;

  const _ClassInfo({required this.title, required this.imageUrl});
}

class _ClassThumbnailCard extends StatelessWidget {
  final _ClassInfo info;

  const _ClassThumbnailCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShadCard(
      padding: EdgeInsets.zero,
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

