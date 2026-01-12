# LidaPay Branding Guide

## Overview
This document outlines the branding guidelines for the LidaPay mobile application.

## Brand Identity

### Brand Name
- **Full Name**: LidaPay
- **Short Name**: Lida
- **Tagline**: "Your Digital Financial Partner"
- **Alternative Tagline**: "Your trusted payment partner"

### Brand Description
International and local airtime and internet data remittance app for Ghana.

## Color Palette

### Primary Colors
- **Primary Pink/Magenta**: `#EC4899` (RGB: 236, 72, 153)
  - Used for: Primary actions, highlights, gradients, CTAs
  - Dark variant: `#DB2777`
  - Light variant: `#F472B6`

- **Secondary Dark Blue/Indigo**: `#2D2952` (RGB: 45, 41, 82)
  - Used for: Secondary elements, text, backgrounds
  - Dark variant: `#1E1A3A`
  - Light variant: `#3D3563`

### Gradients
- **Hero Gradient**: Pink to Indigo (`#EC4899` → `#2D2952`)
  - Used for: Hero sections, headers, splash screens
- **Primary Gradient**: Pink shades (`#EC4899` → `#DB2777`)
  - Used for: Buttons, cards, highlights

## Logo

### Logo Design
The LidaPay logo consists of:
1. **Pink C-shaped curve** (left side)
2. **Pink diagonal bar** (center-right)
3. **Two dark blue circular dots** (top-right and bottom-left)

The overall composition resembles a stylized percentage (%) sign, representing financial transactions and calculations.

### Logo Usage

#### Sizes
- **Small**: 40x40px - Used in navigation bars, small cards
- **Medium**: 80x80px - Used in standard cards, lists
- **Large**: 120x120px - Used in hero sections, prominent displays
- **XLarge**: 160x160px - Used in splash screens, login screens

#### Minimum Requirements
- Minimum size: 24x24px
- Minimum padding: 16px around logo
- Always maintain aspect ratio

#### Usage Guidelines
- ✅ Use on solid backgrounds (white, dark, or brand colors)
- ✅ Use with proper contrast
- ✅ Maintain clear space around logo
- ❌ Don't stretch or distort
- ❌ Don't rotate or flip
- ❌ Don't add effects that alter the logo shape

## Typography

### Brand Name Typography
- **Font Weight**: Bold (700)
- **Style**: Sans-serif, modern
- **Usage**: Headlines, app name displays

### Tagline Typography
- **Font Weight**: Regular (400)
- **Style**: Body text
- **Usage**: Subtitles, descriptions

## Implementation

### Using BrandLogo Widget

```dart
import 'package:lidapay/core/widgets/brand_logo.dart';

// Small logo
BrandLogo.small()

// Medium logo
BrandLogo.medium()

// Large logo with text
BrandLogo.large()

// Extra large with text and tagline
BrandLogo.xlarge()
```

### Using Branding Constants

```dart
import 'package:lidapay/core/constants/branding_constants.dart';

// Brand colors
BrandingConstants.brandPrimary
BrandingConstants.brandSecondary
BrandingConstants.brandGradient

// Brand text
BrandingConstants.brandName
BrandingConstants.brandTagline
```

## Splash Screen

### Design
- **Background**: Pink to Indigo gradient
- **Logo**: XLarge size, centered
- **Animation**: Scale and fade in
- **Duration**: 1.5 seconds minimum

### Implementation
Located at: `lib/presentation/features/splash/screens/splash_screen.dart`

## App Icons

### Android
- Location: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Sizes needed:
  - mdpi: 48x48
  - hdpi: 72x72
  - xhdpi: 96x96
  - xxhdpi: 144x144
  - xxxhdpi: 192x192

### iOS
- Location: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Multiple sizes required (see iOS guidelines)

### Web
- Location: `web/icons/`
- Sizes: 192x192, 512x512 (maskable versions included)

## Color Usage Guidelines

### Primary Actions
- Use primary pink for:
  - Primary buttons
  - Active states
  - Important highlights
  - Progress indicators

### Secondary Elements
- Use dark blue for:
  - Secondary buttons
  - Text on light backgrounds
  - Borders and dividers
  - Inactive states

### Gradients
- Use hero gradient for:
  - Headers and hero sections
  - Splash screens
  - Premium features
  - Special highlights

## Brand Voice

### Tone
- Professional yet approachable
- Trustworthy and reliable
- Modern and innovative
- User-focused

### Messaging
- Emphasize: Security, Speed, Convenience
- Focus on: User benefits, simplicity
- Avoid: Technical jargon, complexity

## File Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── branding_constants.dart    # Brand constants
│   └── widgets/
│       └── brand_logo.dart            # Logo widget
└── presentation/
    └── features/
        └── splash/
            └── screens/
                └── splash_screen.dart  # Splash screen
```

## Assets Required

### Images
- `assets/images/logo.png` - Full color logo
- `assets/images/logo_white.png` - White logo for dark backgrounds
- `assets/images/splash_logo.png` - Splash screen logo

### Icons
- `assets/icons/logo_icon.png` - App icon source

## Next Steps

1. ✅ Create branding constants
2. ✅ Create BrandLogo widget
3. ✅ Update login screen
4. ✅ Create splash screen
5. ✅ Update web manifest
6. ⏳ Generate app icons (all sizes)
7. ⏳ Add logo image assets
8. ⏳ Update Android splash screen XML
9. ⏳ Update iOS configuration
10. ⏳ Add branding to other key screens

## Resources

- Primary Color: `#EC4899`
- Secondary Color: `#2D2952`
- Gradient: `LinearGradient(colors: [#EC4899, #2D2952])`

