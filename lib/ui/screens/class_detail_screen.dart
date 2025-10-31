import 'package:flutter/material.dart';
import '../components/branded_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/website_content.dart';
import '../../services/website_scraper.dart';
import '../theme/shadcn_theme.dart';
import '../components/button.dart';
import '../components/card.dart';

class ClassDetailScreen extends StatefulWidget {
  final String title;

  const ClassDetailScreen({super.key, required this.title});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  static const String _curricularThumbnailUrl =
      'https://www.vidyapith.org/uploads/5/2/1/3/52135817/6185815.jpeg';

  late final WebsiteScraper _scraper;
  Future<CurricularClassesContent>? _curricularFuture;
  Future<MusicClassesContent>? _musicFuture;
  Future<SummerCampContent>? _summerCampFuture;

  bool get _isCurricular =>
      widget.title.toLowerCase().trim() == 'curricular classes';

  bool get _isMusicClasses =>
      widget.title.toLowerCase().trim() == 'music classes';

  bool get _isSummerCamp => widget.title.toLowerCase().trim() == 'summer camp';

  @override
  void initState() {
    super.initState();
    _scraper = WebsiteScraper();
    if (_isCurricular) {
      _curricularFuture = _scraper.fetchCurricularClassesContent(
        thumbnailOverride: _curricularThumbnailUrl,
      );
    } else if (_isMusicClasses) {
      _musicFuture = _scraper.fetchMusicClassesContent();
    } else if (_isSummerCamp) {
      _summerCampFuture = _scraper.fetchSummerCampContent();
    }
  }

  @override
  void dispose() {
    _scraper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: buildBrandedAppBar(title: Text(widget.title)),
      body: _isCurricular
          ? _buildCurricularBody(theme, isDark)
          : _isMusicClasses
          ? _buildMusicBody(theme, isDark)
          : _isSummerCamp
          ? _buildSummerCampBody(theme, isDark)
          : _buildPlaceholder(theme, isDark),
    );
  }

  Widget _buildCurricularBody(ThemeData theme, bool isDark) {
    final future = _curricularFuture;
    if (future == null) {
      return _buildErrorState(theme, isDark);
    }

    return FutureBuilder<CurricularClassesContent>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorState(theme, isDark);
        }

        final content = snapshot.data!;
        return _buildCurricularContent(content, theme, isDark);
      },
    );
  }

  Widget _buildCurricularContent(
    CurricularClassesContent content,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.thumbnailUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  content.thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      color: isDark ? ShadCNTheme.darkMuted : ShadCNTheme.muted,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark ? ShadCNTheme.darkMuted : ShadCNTheme.muted,
                      alignment: Alignment.center,
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
          if (content.thumbnailUrl.isNotEmpty)
            const SizedBox(height: ShadCNTheme.space4),
          _buildSection(
            content.youngstersSection,
            theme,
            isDark,
            overrideTitle:
                'Vidyapith Curricular Classes for Kindergarten through 12th Grade',
          ),
          const SizedBox(height: ShadCNTheme.space3),
          _buildSection(content.adultsSection, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildSection(
    CurricularClassesSection section,
    ThemeData theme,
    bool isDark, {
    String? overrideTitle,
  }) {
    List<String> paragraphs = section.description
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Remove the duplicate "for Youngsters, Kindergarten through to 12th Grade" text
    if (overrideTitle != null) {
      paragraphs = paragraphs.where((paragraph) {
        final lower = paragraph.toLowerCase();
        return !lower.contains('for youngsters') &&
            !lower.contains('kindergarten through to 12th grade');
      }).toList();
    }

    final String displayTitle = overrideTitle ?? section.title;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final scheduleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
      height: 1.5,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayTitle, style: titleStyle),
          if (section.schedule.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space2),
            Text(section.schedule, style: scheduleStyle),
          ],
          if (paragraphs.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space3),
            for (int i = 0; i < paragraphs.length; i++) ...[
              Text(paragraphs[i], style: bodyStyle),
              if (i != paragraphs.length - 1)
                const SizedBox(height: ShadCNTheme.space2),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMusicBody(ThemeData theme, bool isDark) {
    final future = _musicFuture;
    if (future == null) {
      return _buildMusicErrorState(theme, isDark);
    }

    return FutureBuilder<MusicClassesContent>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildMusicErrorState(theme, isDark);
        }

        final content = snapshot.data!;
        return _buildMusicContent(content, theme, isDark);
      },
    );
  }

  Widget _buildMusicContent(
    MusicClassesContent content,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 768;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMusicSection(
                    content.vocalSection,
                    content.vocalThumbnailUrl,
                    theme,
                    isDark,
                  ),
                ),
                const SizedBox(width: ShadCNTheme.space4),
                Expanded(
                  child: _buildMusicSection(
                    content.tablaSection,
                    content.tablaThumbnailUrl,
                    theme,
                    isDark,
                  ),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMusicSection(
                  content.vocalSection,
                  content.vocalThumbnailUrl,
                  theme,
                  isDark,
                ),
                const SizedBox(height: ShadCNTheme.space6),
                _buildMusicSection(
                  content.tablaSection,
                  content.tablaThumbnailUrl,
                  theme,
                  isDark,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMusicSection(
    MusicClassSection section,
    String thumbnailUrl,
    ThemeData theme,
    bool isDark,
  ) {
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final teacherStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );
    final scheduleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: isDark
          ? ShadCNTheme.darkMutedForeground
          : ShadCNTheme.mutedForeground,
    );
    final descriptionStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
      height: 1.5,
    );

    return ShadCard(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnailUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: isDark ? ShadCNTheme.darkCard : ShadCNTheme.card,
                  alignment: Alignment.center,
                  child: Image.network(
                    thumbnailUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Container(
                        color: isDark ? ShadCNTheme.darkCard : ShadCNTheme.card,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? ShadCNTheme.darkCard : ShadCNTheme.card,
                        alignment: Alignment.center,
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
            ),
            const SizedBox(height: ShadCNTheme.space3),
          ],
          Text(section.title, style: titleStyle),
          if (section.teachers.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space2),
            Text('Taught by ${section.teachers}', style: teacherStyle),
          ],
          if (section.schedule.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space2),
            Text(section.schedule, style: scheduleStyle),
          ],
          if (section.description.isNotEmpty) ...[
            const SizedBox(height: ShadCNTheme.space3),
            Text(section.description, style: descriptionStyle),
          ],
          if (section.formUrl != null && section.formUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: ShadCNTheme.space4),
              child: ShadButton(
                text: 'OPEN INQUIRY FORM',
                onPressed: () => _handleFormUrl(section.formUrl!),
                fullWidth: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMusicThumbnail(String url, ThemeData theme, bool isDark) {
    final Color backgroundColor = theme.scaffoldBackgroundColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
      child: Container(
        color: backgroundColor,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Container(
                color: backgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: backgroundColor,
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
    );
  }

  Future<void> _handleFormUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open form. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open form. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open form. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSummerCampBody(ThemeData theme, bool isDark) {
    final future = _summerCampFuture;
    if (future == null) {
      return _buildSummerCampErrorState(theme, isDark);
    }

    return FutureBuilder<SummerCampContent>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildSummerCampErrorState(theme, isDark);
        }

        final content = snapshot.data!;
        return _buildSummerCampContent(content, theme, isDark);
      },
    );
  }

  Widget _buildSummerCampContent(
    SummerCampContent content,
    ThemeData theme,
    bool isDark,
  ) {
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: ShadCNTheme.fontBold,
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? ShadCNTheme.darkCardForeground
          : ShadCNTheme.cardForeground,
      height: 1.5,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShadCNTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadCard(
            padding: const EdgeInsets.all(ShadCNTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.thumbnailUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ShadCNTheme.radiusLg),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: isDark ? ShadCNTheme.darkCard : ShadCNTheme.card,
                        alignment: Alignment.center,
                        child: Image.network(
                          content.thumbnailUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              color: isDark
                                  ? ShadCNTheme.darkCard
                                  : ShadCNTheme.card,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark
                                  ? ShadCNTheme.darkCard
                                  : ShadCNTheme.card,
                              alignment: Alignment.center,
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
                  ),
                  const SizedBox(height: ShadCNTheme.space3),
                ],
                Text(content.title, style: titleStyle),
                if (content.description.isNotEmpty) ...[
                  const SizedBox(height: ShadCNTheme.space3),
                  Text(content.description, style: bodyStyle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummerCampErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ShadCNTheme.space6),
        child: Text(
          'Unable to load summer camp information right now. Please try again later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ShadCNTheme.darkMutedForeground
                : ShadCNTheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ShadCNTheme.space6),
        child: Text(
          'Details coming soon.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark
                ? ShadCNTheme.darkMutedForeground
                : ShadCNTheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMusicErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ShadCNTheme.space6),
        child: Text(
          'Unable to load music classes right now. Please try again later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ShadCNTheme.darkMutedForeground
                : ShadCNTheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ShadCNTheme.space6),
        child: Text(
          'Unable to load curricular classes right now. Please try again later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ShadCNTheme.darkMutedForeground
                : ShadCNTheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
