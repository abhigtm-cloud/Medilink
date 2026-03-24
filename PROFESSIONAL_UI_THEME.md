# MEDILINK Professional UI Theme Guide

## Overview
The MEDILINK application now features a modern, professional healthcare UI theme built on Material Design 3 principles. The theme uses a medical-grade blue color palette suitable for healthcare platforms.

## Color Palette

### Primary Colors
- **Primary Blue** `#0066CC` - Main brand color for buttons, highlights, and primary elements
- **Primary Dark** `#004999` - Darker shade for pressed states and gradients
- **Primary Light** `#3399FF` - Lighter shade for hover states and subtle highlights
- **Primary Very Light** `#E3F2FD` - Background tint for primary-colored elements

### Secondary Colors (Teal Accent)
- **Secondary** `#00BCD4` - Accent color for secondary actions
- **Secondary Light** `#80DEEA` - Lighter accent for backgrounds
- **Secondary Very Light** `#B2EBF2` - Very light tint

### Status Colors
- **Success** `#4CAF50` - For positive actions and confirmations
- **Warning** `#FFC107` - For cautionary messages
- **Error / Alert** `#EF5350` - For errors and critical notifications
- **Info** `#2196F3` - For informational messages

### Neutral Colors (Light Theme)
- **Surface** `#F8FBFF` - Main background color
- **Card** `#FFFFFF` - Card backgrounds
- **Border** `#E0E8F0` - Border color
- **Divider** `#EEF2F7` - Divider lines
- **Text Primary** `#0D1B2A` - Primary text color
- **Text Secondary** `#546E7A` - Secondary text color
- **Text Tertiary** `#90A4AE` - Tertiary text color

### Neutral Colors (Dark Theme)
- **Surface** `#0F1419` - Main background
- **Card** `#1A2332` - Card backgrounds
- **Border** `#2C3E50` - Border color
- **Text Primary** `#FFFFFF` - Primary text
- **Text Secondary** `#BDCAFF` - Secondary text

## Typography

### Font Family
- **Font**: Google Fonts - **Inter**
- Consistent, modern, and highly readable across all screen sizes

### Type Scale

#### Display Styles
- **Display Large**: 32px, Weight 700
- **Display Medium**: 28px, Weight 700
- **Display Small**: 24px, Weight 600

#### Headline Styles
- **Headline Medium**: 22px, Weight 700
- **Headline Small**: 18px, Weight 600

#### Title Styles
- **Title Large**: 16px, Weight 700
- **Title Medium**: 14px, Weight 600
- **Title Small**: 12px, Weight 600

#### Body Styles
- **Body Large**: 16px, Weight 500, Line Height 1.5
- **Body Medium**: 14px, Weight 400, Line Height 1.43
- **Body Small**: 12px, Weight 400, Line Height 1.33

#### Label Styles
- **Label Large**: 14px, Weight 700
- **Label Medium**: 12px, Weight 600
- **Label Small**: 11px, Weight 700

## Component Styling

### Buttons

#### Primary Button
- Background: Primary Blue (#0066CC)
- Foreground: White
- Elevation: 4px with primary shadow
- Padding: 16px vertical, 32px horizontal
- Border Radius: 8px
- Font: 16px, Bold

#### Secondary (Outlined) Button
- Foreground: Primary Blue
- Border: 2px Primary Blue
- Padding: 14px vertical, 28px horizontal
- No elevation
- Border Radius: 8px

#### Text Button (Ghost)
- No background or elevation
- Foreground: Primary Blue
- Minimal padding

### Input Fields
- **Fill Color**: White (light), Card Dark (dark theme)
- **Border**: 1.5px in Border Color
- **Focused Border**: 2px in Primary Blue
- **Border Radius**: 8px
- **Content Padding**: 16px horizontal, 16px vertical
- **Label Display**: Floating

### Cards
- **Elevation**: 2px
- **Border**: 1px in Border Color
- **Border Radius**: 16px
- **Shadow**: Soft 12px blur with primary color at 6% opacity
- **Padding**: 20px
- **Margin**: 0 (cards control their own spacing)

### AppBar
- **Elevation**: 1px
- **Center Title**: Yes
- **Background**: White (light), Card Dark (dark theme)
- **Shadow**: Primary color at 5% opacity
- **Icon Size**: 24px

### Floating Action Button
- **Background**: Primary Blue
- **Foreground**: White
- **Elevation**: 4px
- **Border Radius**: 16px

### Chips
- **Background**: Primary Light at 10% opacity
- **Selected Background**: Primary Blue
- **Border Radius**: 20px with 1px border
- **Label**: Semibold 12px

## Available UI Components

### AppUIComponents Class
Located in `lib/core/theme/app_ui_components.dart`, provides:

#### Cards
- `buildCard()` - Standard professional card
- `buildGradientCard()` - Gradient background card
- `buildListItemCard()` - List item card with divider option

#### Buttons
- `buildPrimaryButton()` - Full-width primary button with loading state
- `buildSecondaryButton()` - Outline secondary button
- `buildGhostButton()` - Text-only ghost button

#### Input
- `buildTextField()` - Professional text input with label and validation

#### Headers
- `buildScreenHeader()` - Screen title with optional subtitle

#### Info & Status
- `buildInfoBanner()` - Alert/notice banner with icon
- `buildBadge()` - Status badge indicator
- `buildEmptyState()` - Empty state with icon and action button

#### Utilities
- `buildShimmerLoader()` - Skeleton loading placeholder
- `buildDividerWithText()` - Divider with center text

### AppColors Class
Located in `lib/core/theme/app_colors.dart`, provides:

- Pre-defined color constants
- Theme-aware color getters:
  - `getTextPrimary(context)` - Gets appropriate text color for theme
  - `getTextSecondary(context)` - Gets secondary text color
  - `getSurface(context)` - Gets surface color
  - `getCard(context)` - Gets card background color
  - `getBorder(context)` - Gets border color

## Shadows & Elevation

### Elevated Shadow
```dart
AppTheme.elevatedShadow
```
Two-layer shadow for prominent elevation:
- Primary shadow: 16px blur, 4px offset
- Secondary shadow: 8px blur, 2px offset

### Card Shadow
```dart
AppTheme.cardShadow
```
Soft shadow for cards: 12px blur, 2px offset

## Gradients

### Primary Gradient
```dart
AppTheme.primaryGradient
```
Linear gradient from Primary to Primary Dark

### Healthcare Gradient
```dart
AppTheme.healthcareGradient
```
Gradient from Primary to Secondary

### Subtle Gradient
```dart
AppTheme.subtleGradient
```
Light background gradient for subtle backgrounds

## Dark Mode Support

The app fully supports both light and dark themes with:
- Automatic theme switching based on system settings
- Identical component styling in both themes
- Color adjustments for readability in dark mode
- All components automatically adapt

## Spacing Guidelines

### Standard Spacing
- Extra Small: 4px
- Small: 8px
- Medium: 16px
- Large: 24px
- Extra Large: 32px
- 2X Large: 40px

### Component Spacing
- Vertical gap between form fields: 20px
- Horizontal padding: 24px
- Vertical padding (content sections): 40px

## Using the Theme in Your Code

### Access Theme Colors
```dart
import 'package:medilink/core/theme/app_colors.dart';

Color textColor = AppColors.textPrimaryLight;
Color primaryColor = AppColors.primary;
```

### Use Pre-built Components
```dart
import 'package:medilink/core/theme/app_ui_components.dart';

// Build a button
AppUIComponents.buildPrimaryButton(
  label: 'Continue',
  onPressed: () {},
);

// Build a card
AppUIComponents.buildCard(
  child: Text('Card content'),
);
```

### Get Theme Data
```dart
import 'package:medilink/core/theme/app_theme.dart';

// Access shadows
List<BoxShadow> shadow = AppTheme.elevatedShadow;

// Access gradients
LinearGradient gradient = AppTheme.primaryGradient;
```

### Build with Theme Colors
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.cardLight,
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppTheme.cardShadow,
  ),
  child: const Text('Styled container'),
)
```

## Best Practices

1. **Use Component Library**: Always use `AppUIComponents` for consistent UI patterns
2. **Color Constants**: Reference `AppColors` instead of hardcoding hex values
3. **Typography**: Let the theme's text styles handle typography automatically
4. **Spacing**: Maintain consistent spacing using standard values (8, 16, 24, 32, 40)
5. **Icons**: Use outlined icons for inputs and subtle operations; solid for primary actions
6. **Shadows**: Use `AppTheme.elevatedShadow` for prominent components, `cardShadow` for cards
7. **Border Radius**: Use 16 for cards, 8 for buttons, 20 for chips
8. **Responsiveness**: Design mobile-first, test on different screen sizes

## Implementation Examples

### Professional Login Screen
See [lib/features/auth/screens/login_screen.dart](../features/auth/screens/login_screen.dart) for a complete example of using the new theme.

### Updating Existing Screens
Replace hardcoded colors with `AppColors` constants and use `AppUIComponents` for UI patterns.

## Future Enhancements

- [ ] Animation guidelines and pre-built transitions
- [ ] Custom shape patterns for medical/healthcare imagery
- [ ] Accessibility guidelines and checklist
- [ ] Component storybook/showcase screen
- [ ] Theme customization panel

---

**Theme Version**: 2.0 Professional Healthcare Edition  
**Last Updated**: March 2026  
**Material Design Version**: Material 3
