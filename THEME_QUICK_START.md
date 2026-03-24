# Quick Start Guide: Applying the Professional Theme

## 🚀 How to Apply the New Theme to Your Screens

### Step 1: Import the Theme Components

Add these imports to any screen file:

```dart
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_ui_components.dart';
import 'package:medilink/core/theme/app_theme.dart';
```

### Step 2: Replace Colors

**Before (Old Way):**
```dart
Container(
  color: const Color(0xFF20B2AA),
  child: Text(
    'Hello',
    style: TextStyle(color: const Color(0xFF1A1A2E)),
  ),
)
```

**After (New Way):**
```dart
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimaryLight),
  ),
)
```

### Step 3: Use Professional Components

**Before (Custom Implementation):**
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: const Text('Click Me'),
)
```

**After (Reusable Component):**
```dart
AppUIComponents.buildPrimaryButton(
  label: 'Click Me',
  onPressed: () {},
)
```

### Step 4: Apply to Cards

**Before:**
```dart
Card(
  elevation: 2,
  child: Container(
    padding: EdgeInsets.all(16),
    color: Colors.white,
    child: Text('Card content'),
  ),
)
```

**After:**
```dart
AppUIComponents.buildCard(
  child: Text('Card content'),
  padding: const EdgeInsets.all(20),
)
```

### Step 5: Use Theme Utilities

**Shadows:**
```dart
Container(
  boxShadow: AppTheme.elevatedShadow,
  // or
  boxShadow: AppTheme.cardShadow,
)
```

**Gradients:**
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,
    borderRadius: BorderRadius.circular(16),
  ),
)
```

## 📋 Component Reference

### Cards
```dart
// Standard card
AppUIComponents.buildCard(
  child: Text('Content'),
  backgroundColor: AppColors.cardLight,
)

// Gradient card
AppUIComponents.buildGradientCard(
  child: Text('Content'),
  gradient: AppTheme.primaryGradient,
)

// List item card
AppUIComponents.buildListItemCard(
  child: Row(children: [...]),
  showDivider: true,
)
```

### Buttons
```dart
// Primary button
AppUIComponents.buildPrimaryButton(
  label: 'Save',
  onPressed: () {},
  isLoading: false,
)

// Secondary button
AppUIComponents.buildSecondaryButton(
  label: 'Cancel',
  onPressed: () {},
)

// Ghost button
AppUIComponents.buildGhostButton(
  label: 'Learn More',
  onPressed: () {},
  color: AppColors.primary,
)
```

### Input Fields
```dart
AppUIComponents.buildTextField(
  controller: _controller,
  label: 'Email',
  hint: 'your@email.com',
  prefixIcon: Icons.email_outlined,
  validator: (value) {
    if (value?.isEmpty) return 'Required';
    return null;
  },
)
```

### Status Components
```dart
// Badge
AppUIComponents.buildBadge(
  label: 'Active',
  backgroundColor: AppColors.success,
  textColor: Colors.white,
)

// Info banner
AppUIComponents.buildInfoBanner(
  message: 'This is important!',
  backgroundColor: AppColors.warning,
  textColor: Colors.white,
  icon: Icons.warning_rounded,
)

// Empty state
AppUIComponents.buildEmptyState(
  icon: Icons.inbox_outlined,
  title: 'No Data',
  subtitle: 'No items to display',
  actionLabel: 'Retry',
  onActionPressed: () {},
)
```

## 🎨 Common Screen Updates

### List Screen Example
```dart
Scaffold(
  appBar: AppBar(
    title: const Text('My List'),
    backgroundColor: AppColors.cardLight,
  ),
  backgroundColor: AppColors.surfaceLight,
  body: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => AppUIComponents.buildListItemCard(
      child: ListTile(
        title: Text(
          items[index].title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          items[index].subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      showDivider: true,
    ),
  ),
)
```

### Detail Screen Example
```dart
Scaffold(
  backgroundColor: AppColors.surfaceLight,
  body: SingleChildScrollView(
    child: Column(
      children: [
        // Header with gradient
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Content cards
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppUIComponents.buildCard(
            child: Column(
              children: [
                Text(
                  'Content',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
)
```

## ✅ Checklist for Theme Updates

- [ ] Import theme components
- [ ] Replace hardcoded colors with AppColors
- [ ] Use theme text styles (Theme.of(context).textTheme)
- [ ] Replace custom components with AppUIComponents
- [ ] Apply AppTheme shadows to containers
- [ ] Test on light theme
- [ ] Test on dark theme
- [ ] Verify shadows and gradients render correctly
- [ ] Check text contrast for accessibility

## 🎯 Priority Screens to Update

1. **High Priority** (User-facing)
   - home_screen.dart
   - doctor_list_screen.dart
   - booking_screen.dart
   - bookings_screen.dart

2. **Medium Priority** (Admin-facing)
   - admin_dashboard_screen.dart
   - add_hospital_screen.dart
   - hospital_detail_screen.dart

3. **Low Priority** (Secondary)
   - account_screen.dart
   - search_screen.dart

## 💡 Pro Tips

1. **Use Theme.of(context).textTheme** for all text styling
2. **Always use AppColors** instead of hardcoded hex values
3. **Leverage AppUIComponents** for consistency
4. **Test dark mode** while developing
5. **Use EdgeInsets.symmetric()** for consistent spacing
6. **Apply shadows from AppTheme** for professional look
7. **Create custom cards with AppUIComponents.buildCard()**

## 🐛 Troubleshooting

**Theme not applying?**
- Ensure imports are correct
- Check that you're using the latest theme classes
- Restart the development server

**Colors look different?**
- Verify dark mode isn't enabled unexpectedly
- Check color names in AppColors
- Ensure proper contrast

**Components not showing?**
- Import AppUIComponents
- Pass required parameters
- Check widget is inside proper parent

---

For more details, see **PROFESSIONAL_UI_THEME.md**
