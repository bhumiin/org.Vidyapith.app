# Vidyapith Hybrid App

A Flutter mobile application for Vivekananda Vidyapith that displays website content in a native mobile interface. The app features web scraping, local caching, and offline support.

## 📱 Project Overview

This is a **hybrid mobile app** that combines native Flutter UI with web content from the Vidyapith website. The app automatically scrapes content from https://www.vidyapith.org and caches it locally for offline access.

### Key Features

- **Home Screen**: Daily quotes, upcoming events, photo carousel, and quick links
- **About Section**: Information about Vidyapith
- **Events**: List of past and upcoming events with images
- **Calendar**: PDF calendar viewer
- **Contact**: Contact information, forms, and email addresses
- **Offline Support**: Cached content works without internet connection
- **Pull-to-Refresh**: Refresh content by pulling down
- **Dark Mode**: Automatic theme switching based on device settings

## 🛠️ Tech Stack

### Core Framework
- **Flutter 3.x** - Cross-platform mobile framework
- **Dart 3.9.2+** - Programming language

### Key Dependencies

| Package | Purpose | Version |
|---------|---------|---------|
| `webview_flutter` | Display web pages inside the app | ^4.10.0 |
| `http` | Make HTTP requests to fetch web pages | ^1.2.2 |
| `html` | Parse HTML and extract content | ^0.15.4 |
| `shared_preferences` | Local storage for caching content | ^2.3.2 |
| `connectivity_plus` | Detect internet connection status | ^6.0.3 |
| `pull_to_refresh` | Pull-to-refresh functionality | ^2.0.0 |
| `url_launcher` | Open external URLs | ^6.3.0 |
| `google_fonts` | Custom typography | ^6.2.1 |
| `flutter_animate` | UI animations | ^4.5.0 |

### Why These Technologies?

- **Flutter**: Write once, run on both iOS and Android. Excellent performance and large community.
- **Web Scraping**: Extracts structured data from the website without needing a backend API.
- **Local Caching**: Reduces network calls, enables offline access, and improves performance.
- **WebView**: Displays website pages natively within the app without opening external browser.

## 📁 Project Structure

```
vidyapith_hybrid_app/
│
├── lib/                          # Main source code
│   ├── main.dart                 # App entry point - starts the app
│   │
│   ├── models/                   # Data structures (blueprints)
│   │   ├── calendar_event.dart   # Structure for calendar events
│   │   └── website_content.dart # Structure for website data
│   │
│   ├── services/                 # Business logic
│   │   ├── website_scraper.dart # Downloads & extracts content from website
│   │   ├── calendar_scraper.dart # Extracts calendar information
│   │   └── daily_refresh.dart   # Handles automatic content refreshing
│   │
│   └── ui/                       # User interface
│       ├── screens/              # Full-page screens
│       │   ├── home_screen.dart  # Main landing page
│       │   ├── about_screen.dart # About page
│       │   ├── events_screen.dart# Events listing
│       │   ├── calendar_screen.dart # Calendar view
│       │   └── contact_screen.dart  # Contact information
│       │
│       ├── components/           # Reusable UI components
│       │   ├── button.dart      # Custom button design
│       │   ├── card.dart         # Card container
│       │   ├── photo_carousel.dart # Image slideshow
│       │   └── ...               # Other reusable components
│       │
│       └── theme/                # App-wide styling
│           └── shadcn_theme.dart # Colors, fonts, spacing
│
├── assets/                       # Images, fonts, etc.
│   └── images/                   # Logo, letterhead, etc.
│
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
├── pubspec.yaml                  # Project dependencies & configuration
└── README.md                     # This file
```

## 🏗️ Architecture

The project follows **Clean Architecture** principles with clear separation of concerns:

- **Models** (`lib/models/`): Data structures that represent the app's data
- **Services** (`lib/services/`): Business logic (web scraping, caching, data processing)
- **UI** (`lib/ui/`): Presentation layer (screens, components, themes)

### State Management

- Uses `setState()` for local widget state management
- `ValueNotifier` for cross-widget communication (scroll, refresh)
- No global state management library (keeps it simple)

### How It Works

1. **App Launch**: Shows splash screen, then navigates to main screen with bottom navigation
2. **Content Fetching**: `WebsiteScraper` downloads HTML from the website
3. **Parsing**: HTML is parsed to extract quotes, events, images, contact info
4. **Caching**: Content is stored locally using `shared_preferences` (24-hour cache)
5. **Display**: UI components render the cached/fresh content
6. **Refresh**: Users can pull-to-refresh or content auto-refreshes after cache expires

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (version 3.9.2 or higher)
   - Download from: https://docs.flutter.dev/get-started/install
   - Verify installation: `flutter doctor`

2. **Development Tools**
   - **Android Studio** (for Android development)
     - Install Android SDK and Android Emulator
   - **Xcode** (for iOS development - macOS only)
     - Install Xcode Command Line Tools: `xcode-select --install`
   - **VS Code** or **Android Studio** (recommended IDE with Flutter extensions)

3. **Git** (for version control)
   - Download from: https://git-scm.com/downloads

### Step 1: Clone or Download the Project

#### Option A: Clone from Git Repository

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/vidyapith_hybrid_app.git

# Navigate to project directory
cd vidyapith_hybrid_app
```

#### Option B: Download ZIP

1. Download the project ZIP file
2. Extract it to your desired location
3. Navigate to the project folder in terminal

### Step 2: Install Dependencies

```bash
# Get all Flutter packages
flutter pub get

# This will download all dependencies listed in pubspec.yaml
```

### Step 3: Set Up Android Development (Optional - for Android builds)

1. **Create `android/local.properties`**:
   ```bash
   # Navigate to android folder
   cd android
   
   # Create local.properties file
   # On macOS/Linux:
   echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties
   echo "flutter.sdk=$(flutter --version --machine | grep 'flutterRoot' | cut -d'"' -f4)" >> local.properties
   
   # On Windows:
   # Create local.properties manually with:
   # sdk.dir=C:\\Users\\YourUsername\\AppData\\Local\\Android\\sdk
   # flutter.sdk=C:\\path\\to\\flutter
   ```

2. **For Release Builds** (optional):
   - Create `android/key.properties` with your signing configuration
   - See [Android App Signing](https://docs.flutter.dev/deployment/android#signing-the-app) for details

### Step 4: Set Up iOS Development (Optional - macOS only, for iOS builds)

```bash
# Navigate to ios folder
cd ios

# Install CocoaPods dependencies
pod install

# Return to project root
cd ..
```

**Note**: If `pod install` fails, try:
```bash
# Update CocoaPods
sudo gem install cocoapods

# Clean and reinstall
rm -rf Pods Podfile.lock
pod install
```

### Step 5: Verify Setup

```bash
# Check Flutter installation
flutter doctor

# List available devices/emulators
flutter devices

# Run Flutter analyzer to check for issues
flutter analyze
```

### Step 6: Run the App

```bash
# Run on a connected device or emulator
flutter run

# Or specify a device
flutter run -d <device-id>

# Run in release mode (faster, no debugging)
flutter run --release

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d macos            # macOS
flutter run -d windows          # Windows
flutter run -d linux            # Linux
```

## 📋 Making Your Own Copy for Development

### Method 1: Fork the Repository (Recommended)

If the project is on GitHub/GitLab:

1. Click "Fork" button on the repository page
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/vidyapith_hybrid_app.git
   cd vidyapith_hybrid_app
   ```
3. Add original as upstream (to pull updates):
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/vidyapith_hybrid_app.git
   ```

### Method 2: Clone and Create New Branch

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/vidyapith_hybrid_app.git
cd vidyapith_hybrid_app

# Create a new branch for your development
git checkout -b feature/your-feature-name

# Make your changes, then commit
git add .
git commit -m "Your commit message"
```

### Method 3: Copy the Entire Folder

```bash
# Copy the project folder
cp -r vidyapith_hybrid_app vidyapith_hybrid_app_my_copy
cd vidyapith_hybrid_app_my_copy

# Remove git history (start fresh)
rm -rf .git

# Initialize new git repository (optional)
git init
git add .
git commit -m "Initial commit - my copy"
```

### Method 4: Download ZIP and Extract

1. Download the project as ZIP
2. Extract to a new folder
3. Rename the folder to your preference
4. Open in your IDE and start developing

## 🔧 Development Workflow

### Running the App

```bash
# Development mode (with hot reload)
flutter run

# Release mode (optimized)
flutter run --release

# Profile mode (performance testing)
flutter run --profile
```

### Hot Reload

While the app is running:
- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Building for Production

#### Android

```bash
# Build APK
flutter build apk

# Build App Bundle (for Play Store)
flutter build appbundle

# Output location: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS

```bash
# Build iOS app (macOS only)
flutter build ios

# Then open ios/Runner.xcworkspace in Xcode to archive and upload
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Flutter Doctor Shows Issues

```bash
# Run flutter doctor to see what's missing
flutter doctor

# Fix Android licenses (if needed)
flutter doctor --android-licenses
```

#### 2. Build Errors

```bash
# Clean build cache
flutter clean

# Get dependencies again
flutter pub get

# Rebuild
flutter run
```

#### 3. iOS Pod Issues

```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

#### 4. Android Build Fails

- Check `android/local.properties` has correct paths
- Ensure Android SDK is properly installed
- Verify `key.properties` exists if building release (or remove signing config)

#### 5. WebView Not Loading

- Check internet connection
- Verify the website URL is accessible
- Check device logs: `flutter logs`

#### 6. Dependencies Not Found

```bash
# Clear pub cache
flutter pub cache repair

# Get dependencies again
flutter pub get
```

## 📝 Code Style

The project follows Dart and Flutter style guidelines:

- Use `null safety` throughout
- Prefer `final` and `const` where applicable
- Use DartDoc comments (`///`) for public APIs
- Follow the existing code structure in `lib/` folder
- Keep widgets small and reusable

See `.cursorrules` for detailed coding standards.

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## 📦 Building and Distribution

### Android

1. Build release APK: `flutter build apk --release`
2. Or build App Bundle: `flutter build appbundle --release`
3. Sign the APK/Bundle (if not using automatic signing)
4. Upload to Google Play Console

### iOS

1. Build iOS app: `flutter build ios --release`
2. Open `ios/Runner.xcworkspace` in Xcode
3. Archive the app: Product → Archive
4. Upload to App Store Connect

## 🔐 Security Notes

**Important**: Before sharing or committing:

- ✅ `key.properties` is excluded (contains signing passwords)
- ✅ `local.properties` is excluded (contains local paths)
- ✅ `*.jks` and `*.keystore` files are excluded
- ⚠️ Never commit sensitive credentials or API keys
- ⚠️ Review `.gitignore` before pushing to public repositories

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Material Design 3](https://m3.material.io/)

## 🤝 Contributing

When making changes:

1. Create a new branch for your feature
2. Follow the existing code style
3. Add comments for complex logic
4. Test your changes thoroughly
5. Submit a pull request with clear description

## 📄 License

[Add your license here]

## 👤 Author

Bhumin Desai

## 🙏 Acknowledgments

- Vivekananda Vidyapith for the content
- Flutter team for the amazing framework
- All package maintainers

---

**Happy Coding! 🚀**
