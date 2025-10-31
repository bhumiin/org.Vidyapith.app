# ShadCN UI Components for Flutter

A comprehensive collection of ShadCN-inspired UI components for Flutter applications, providing a modern, accessible, and customizable design system.

## Features

- 🎨 **ShadCN-inspired Design**: Components follow ShadCN's design principles and aesthetics
- 🌙 **Dark Mode Support**: Full dark and light theme support
- 📱 **Responsive**: Components adapt to different screen sizes
- ♿ **Accessible**: Built with accessibility in mind
- 🎯 **Type-safe**: Full TypeScript-like type safety with Dart
- 🧩 **Modular**: Import only what you need
- 🎭 **Customizable**: Easy to customize colors, spacing, and typography

## Components

### Core Components
- **Button** - Various button styles and sizes
- **Card** - Container components with different layouts
- **Input** - Text input fields with validation
- **Badge** - Small status and label components

### Form Components
- **Checkbox** - Single and group checkboxes
- **Radio** - Single and group radio buttons
- **Select** - Dropdown selection components
- **Textarea** - Multi-line text input

### Feedback Components
- **Alert** - Notification and status messages
- **Toast** - Temporary notification overlays
- **Dialog** - Modal dialogs and confirmations

### Layout Components
- **Container** - Flexible container with styling
- **Section** - Content sections with headers
- **Flex** - Flexible layout with spacing
- **Grid** - Grid layout system
- **Stack** - Stacked layout component

## Quick Start

### 1. Import the Theme

```dart
import 'package:your_app/ui/theme/shadcn_theme.dart';

MaterialApp(
  theme: ShadCNTheme.lightTheme,
  darkTheme: ShadCNTheme.darkTheme,
  themeMode: ThemeMode.system,
  // ... rest of your app
)
```

### 2. Use Components

```dart
import 'package:your_app/ui/components/index.dart';

// Button
ShadButton(
  text: 'Click me',
  onPressed: () => print('Button pressed'),
  variant: ShadButtonVariant.primary,
)

// Card
ShadCard(
  child: Text('Card content'),
)

// Input
ShadInput(
  label: 'Email',
  placeholder: 'Enter your email',
  controller: controller,
)

// Alert
ShadAlert(
  title: 'Success',
  description: 'Operation completed successfully!',
  variant: ShadAlertVariant.success,
)
```

## Theme Customization

The theme system is built around ShadCN's design tokens:

### Colors
- Primary, Secondary, Accent colors
- Muted colors for subtle elements
- Destructive colors for errors
- Border and input colors

### Typography
- Inter font family (via Google Fonts)
- Consistent font sizes and weights
- Proper line heights and spacing

### Spacing
- Consistent spacing scale (4px base unit)
- Responsive spacing for different screen sizes

### Border Radius
- Consistent border radius values
- From small (2px) to full rounded (9999px)

## Component Variants

Most components support multiple variants:

### Button Variants
- `default_` - Primary button
- `secondary` - Secondary button
- `destructive` - Destructive action button
- `outline` - Outlined button
- `ghost` - Ghost button
- `link` - Link-style button

### Alert Variants
- `default_` - Default alert
- `success` - Success message
- `warning` - Warning message
- `destructive` - Error message

### Badge Variants
- `default_` - Default badge
- `secondary` - Secondary badge
- `destructive` - Destructive badge
- `outline` - Outlined badge

## Size Variants

Many components support different sizes:

- `sm` - Small size
- `default_` - Default size
- `lg` - Large size

## Examples

### Form with Validation

```dart
ShadInput(
  label: 'Email',
  placeholder: 'Enter your email',
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  errorText: emailError,
  prefixIcon: Icon(Icons.email_outlined),
)
```

### Card with Actions

```dart
ShadCardComplete(
  title: 'User Profile',
  description: 'Manage your account settings',
  content: Column(
    children: [
      // Profile content
    ],
  ),
  footer: Row(
    children: [
      ShadButton(
        text: 'Cancel',
        variant: ShadButtonVariant.outline,
        onPressed: () => Navigator.pop(),
      ),
      SizedBox(width: 8),
      ShadButton(
        text: 'Save',
        onPressed: () => saveProfile(),
      ),
    ],
  ),
)
```

### Alert with Action

```dart
ShadAlert(
  title: 'Update Available',
  description: 'A new version of the app is available.',
  variant: ShadAlertVariant.success,
  action: ShadButton(
    text: 'Update',
    size: ShadButtonSize.sm,
    onPressed: () => updateApp(),
  ),
  onClose: () => dismissAlert(),
)
```

## Best Practices

1. **Consistent Spacing**: Use the theme's spacing constants (`ShadCNTheme.space4`, etc.)
2. **Semantic Colors**: Use semantic color names rather than hardcoded colors
3. **Accessibility**: Always provide labels and helper text for form components
4. **Responsive Design**: Use flexible layouts and responsive spacing
5. **Dark Mode**: Test your components in both light and dark themes

## Contributing

When adding new components:

1. Follow the existing naming convention (`ShadComponentName`)
2. Support both light and dark themes
3. Include proper TypeScript-like type safety
4. Add comprehensive documentation
5. Include examples in the demo screen
6. Follow the established design patterns

## License

This UI component library is part of your Flutter application and follows the same license terms.
