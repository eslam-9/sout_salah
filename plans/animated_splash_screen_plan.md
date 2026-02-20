# Modern Animated Splash Screen Plan

## Overview
This plan outlines the implementation of a modern animated splash screen for the **Sout Salah** Flutter app using a hybrid approach: a native splash screen that seamlessly transitions to a Lottie animated splash screen with Islamic geometric patterns.

## Architecture

### Splash Screen Flow

```mermaid
flowchart TD
    A[App Launch] --> B[Native Splash Screen]
    B --> C[Flutter Engine Initializes]
    C --> D[Lottie Splash Screen]
    D --> E{Animation Complete}
    E --> F[Navigate to Home Screen]
    
    subgraph Native Layer
        B
    end
    
    subgraph Flutter Layer
        D
        E
        F
    end
```

### Component Structure

```mermaid
flowchart LR
    subgraph Assets
        A1[splash_animation.json - Lottie file]
        A2[splash_logo.png - App logo]
    end
    
    subgraph Widgets
        W1[SplashScreen]
        W2[AnimatedLogo]
        W3[LoadingIndicator]
    end
    
    subgraph Configuration
        C1[pubspec.yaml - Dependencies]
        C2[flutter_native_splash - Native config]
        C3[app_routes.dart - Route definition]
    end
    
    A1 --> W1
    A2 --> W2
    W2 --> W1
    W3 --> W1
    C1 --> W1
    C2 --> B
    C3 --> W1
```

## Implementation Details

### 1. Dependencies Required

Add to [`pubspec.yaml`](pubspec.yaml):
```yaml
dependencies:
  lottie: ^3.1.0  # For Lottie animations
```

### 2. File Structure

```
lib/
├── core/
│   ├── presentation/
│   │   └── pages/
│   │       └── splash_screen.dart     # New splash screen widget
│   └── routes/
│       └── app_routes.dart            # Add splash route
assets/
├── animations/
│   └── splash_animation.json          # Placeholder Lottie file
└── splash_logo.png                    # App logo for splash
```

### 3. Native Splash Configuration

Update [`pubspec.yaml`](pubspec.yaml) flutter_native_splash section:
```yaml
flutter_native_splash:
  color: "#2E7D32"  # Match AppColors.primary
  image: assets/splash_logo.png
  
  android: true
  ios: true
  
  android_12:
    image: assets/splash_logo.png
    icon_background_color: "#2E7D32"
    color: "#2E7D32"
```

### 4. SplashScreen Widget Design

The [`SplashScreen`](lib/core/presentation/pages/splash_screen.dart) widget will feature:

- **Background**: Solid color matching native splash - `#2E7D32` (AppColors.primary)
- **Lottie Animation**: Islamic geometric patterns that rotate and fade
- **Logo Reveal**: App logo fades in after geometric animation
- **App Name**: "صوت صلاح" text with fade-in animation
- **Loading Indicator**: Subtle loading animation at bottom

### 5. Animation Sequence

```mermaid
sequenceDiagram
    participant User
    participant Native as Native Splash
    participant Flutter as Flutter Engine
    participant Lottie as Lottie Animation
    participant Home as Home Screen
    
    User->>Native: Launch App
    Native->>Flutter: Initialize Engine
    Note over Native,Flutter: Seamless transition - same background color
    Flutter->>Lottie: Start Animation
    Lottie->>Lottie: Geometric patterns rotate - 1.5s
    Lottie->>Lottie: Logo fades in - 0.5s
    Lottie->>Lottie: App name appears - 0.3s
    Lottie->>Home: Navigate after completion
    Note over Lottie,Home: Total duration: ~2.5-3 seconds
```

### 6. Color Scheme

| Element | Color | Hex Code |
|---------|-------|----------|
| Background | Primary Green | `#2E7D32` |
| Geometric Patterns | Light Green/White | `#E8F5E9` / `#FFFFFF` |
| App Name | White | `#FFFFFF` |
| Loading Indicator | Light Green | `#8AD38C` |

### 7. Lottie Animation Placeholder

The placeholder Lottie file will include:
- Simple geometric shapes (hexagons, stars, circles)
- Rotation and scale animations
- Fade transitions
- Duration: 2-3 seconds

**Note**: You will need to replace the placeholder with a custom Lottie animation from:
- [LottieFiles.com](https://lottiefiles.com) - Search for "Islamic geometric" or "Arabic pattern"
- Custom animation created with Adobe After Effects + Bodymovin plugin
- Hire a designer on Fiverr/Upwork for custom Islamic geometric animation

## Tasks Breakdown

### Phase 1: Setup
- [ ] Add `lottie` package to [`pubspec.yaml`](pubspec.yaml)
- [ ] Create `assets/animations/` directory
- [ ] Add placeholder Lottie JSON file

### Phase 2: Native Splash
- [ ] Update `flutter_native_splash` configuration
- [ ] Run `flutter pub run flutter_native_splash:create`
- [ ] Verify native splash on both Android and iOS

### Phase 3: Flutter Splash Screen
- [ ] Create [`SplashScreen`](lib/core/presentation/pages/splash_screen.dart) widget
- [ ] Implement Lottie animation with controller
- [ ] Add logo and app name with animations
- [ ] Add navigation logic after animation completes

### Phase 4: Integration
- [ ] Add splash route to [`app_routes.dart`](lib/core/routes/app_routes.dart)
- [ ] Update [`main.dart`](lib/main.dart) to use splash as initial route
- [ ] Ensure smooth transition from native to Flutter splash

### Phase 5: Testing & Polish
- [ ] Test on Android devices
- [ ] Test on iOS devices
- [ ] Adjust animation timing
- [ ] Verify no jank or frame drops

## Code Snippets

### SplashScreen Widget Structure

```dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  
  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation
            // Logo with fade animation
            // App name with slide animation
            // Loading indicator
          ],
        ),
      ),
    );
  }
}
```

## Resources

- [Lottie Package](https://pub.dev/packages/lottie)
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)
- [LottieFiles - Islamic Animations](https://lottiefiles.com/search?q=islamic&category=animations)
- [Islamic Geometric Patterns Examples](https://lottiefiles.com/search?q=geometric%20pattern&category=animations)

## Notes

1. **Performance**: Keep Lottie file size under 100KB for optimal performance
2. **Accessibility**: The splash screen should not block users for more than 3 seconds
3. **Branding**: Ensure the splash screen matches the app's Islamic theme and green color scheme
4. **Dark Mode**: Consider adding a dark mode variant of the splash screen
