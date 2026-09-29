# Vidyapith Hybrid App

Flutter app for **Vivekananda Vidyapith** (vidyapith.org). iOS + Android from one codebase.
A *hybrid* app: native Flutter UI over content scraped from the parish website, cached for offline
use. There is no backend API — the website is the data source.

## Stack
- Flutter 3.35.7 (stable), Dart `^3.9.2` (constraint in `pubspec.yaml`)
- State: `setState()` for local widget state; `ValueNotifier` for cross-widget signals
  (scroll/refresh). **No state-management library — do not add one.**
- Backend: **none.** Content comes from scraping `https://www.vidyapith.org` plus a Google
  Calendar ICS feed. `shared_preferences` caches content for 24h.
- Key packages: `http`, `html`, `webview_flutter`, `shared_preferences`, `connectivity_plus`,
  `icalendar_parser`, `url_launcher`, `google_fonts`, `flutter_animate`, `gap`, `flutter_svg`
- Platforms: iOS (CocoaPods, platform 13.0), Android (compileSdk/targetSdk 37, Gradle 9.3.1,
  AGP 9.1.1, minSdk from Flutter)

## Layout (this is the real structure — follow it)

    lib/
      main.dart                 # entry point
      core/                     # constants, URL builders (vidyapith_urls.dart), utils
      models/                   # data structures (calendar_event.dart, website_content.dart)
      services/                 # scraping + caching logic, one file per site section
      ui/
        screens/                # full-page screens
        components/             # reusable widgets (carousels, cards, buttons)
        theme/                  # shadcn_theme.dart — colors, fonts, spacing
    assets/images/
    test/                       # mirrors lib/ — one test file per scraper + widget tests

**Do not create `lib/features/`.** The `.cursorrules` file describes a
`features/<feature>/{presentation,application,domain}` tree that this project never adopted;
that file is stale. This layout is authoritative.

## The scraper pattern (most important thing to know)

Each website section has its own scraper in `lib/services/` with a matching test in `test/`:
admissions, archives, bookstore, donate, music classes, curricular classes, summer camp,
website (home/events), and calendar ICS.
**"Add a section to the app" means: write a scraper + write its test.** Do not invent a
different pattern or introduce a generic fetch layer.

- Scrapers parse HTML from a site we do not control. **Degrade gracefully**: on a parse failure
  or a changed layout, return the fallback/cached content rather than throwing. Existing
  scrapers already do this (see `donate_scraper_test.dart` "uses fallback" cases).
- Never hard-code a new image URL to replace a broken one. Several `vidyapith.org/uploads/...`
  URLs are baked into screens and at least one now 404s; re-pointing it silently hides a site
  change. Report it instead and prefer the URL builder in `lib/core/vidyapith_urls.dart`.
- Site URLs are centralised in `lib/core/vidyapith_urls.dart` — add new ones there, not inline.

## Commands
- `flutter pub get` — after any dependency change
- `flutter analyze` — **baseline is 82 issues** (info/warning only, no errors). Must not add
  new ones. Never do a sweeping cleanup of existing issues as a side effect of an unrelated task.
- `flutter test` — **baseline is 44 passing, 1 skipped.** Must stay green.
- `flutter run` — local device/simulator
- `flutter build apk --release` / `flutter build ios --release`

## Rules
- **Before saying a change is done:** run `flutter analyze` and `flutter test` and paste the
  real output. Quote the actual counts; never claim success without running them.
- Existing analyzer issues: `withOpacity`→`withValues()` and `background`/`onBackground`→
  `surface`/`onSurface` deprecations are safe to fix *in files you are already editing*.
  The `use_build_context_synchronously` warnings in `home_screen.dart` (6) are real crash risks —
  fix them when you touch that code, not as a separate sweep.
- `test/widget_test.dart` is still the untouched Flutter sample (unused `main.dart` import) —
  it is not real coverage. Don't treat it as a smoke test for app behaviour.
- Null safety throughout; `final`/`const` where applicable.
- No `print()` — use `debugPrint()`.
- Dispose controllers and listeners.
- Keep widgets small; extract nested trees into `lib/ui/components/`.
- Business logic belongs in `lib/services/`, not in widgets.
- No global mutable state; pass data via constructors or callbacks.
- No secrets in the repo. `key.properties`, `local.properties`, `*.jks`, `*.keystore` stay ignored.
- Don't bump dependency versions or add packages unless the task requires it.
- Match existing naming and widget style. `lib/ui/theme/shadcn_theme.dart` is the single source
  of colours/spacing — don't hard-code style values in screens.
- One commit per logical change, imperative subject line.

## Commit provenance and history
- End every commit body with: `Assisted-by: Hermes (<model name>)`
- Never commit to `main`; work on `hermes/<topic>` branches only, then open a PR.
- Never force-push, never rewrite history, never delete branches or tags.
- `pre-hermes` (tag) and `cursor-baseline` (branch) mark the last pre-Hermes commit.
  **Never move, overwrite, or delete them.**
- One clone per tool: this directory is Hermes'; the human's Cursor clone is separate.

## Roadmap
- Shipped: home (quotes/events/carousel), about, events, calendar (PDF + ICS), contact,
  snack signup, archives, bookstore, classes/camps, dark mode, offline caching.
- Next: store submission prep (Play Store / App Store), and keeping the scrapers resilient
  as the parish site changes.
