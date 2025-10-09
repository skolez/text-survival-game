import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for platform detection and responsive design
class PlatformUtils {
  /// Check if running on mobile platform (Android or iOS)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Theme.of(NavigationService.navigatorKey.currentContext!).platform ==
            TargetPlatform.android ||
        Theme.of(NavigationService.navigatorKey.currentContext!).platform ==
            TargetPlatform.iOS;
  }

  /// Check if running on desktop platform (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return true; // Treat web as desktop for UI purposes
    final platform =
        Theme.of(NavigationService.navigatorKey.currentContext!).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if running on tablet (based on screen size)
  static bool isTablet(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.shortestSide;

    // Consider tablet if shortest side is >= 600dp (typical tablet threshold)
    return diagonal >= 600;
  }

  /// Get responsive breakpoints
  static ResponsiveBreakpoint getBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return ResponsiveBreakpoint.mobile;
    } else if (width < 1024) {
      return ResponsiveBreakpoint.tablet;
    } else {
      return ResponsiveBreakpoint.desktop;
    }
  }

  /// Get appropriate font size based on platform and screen size
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final breakpoint = getBreakpoint(context);

    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        return baseFontSize * 0.9; // Slightly smaller on mobile
      case ResponsiveBreakpoint.tablet:
        return baseFontSize;
      case ResponsiveBreakpoint.desktop:
        return baseFontSize * 1.1; // Slightly larger on desktop
    }
  }

  /// Get appropriate padding based on platform and screen size
  static EdgeInsets getResponsivePadding(
      BuildContext context, EdgeInsets basePadding) {
    final breakpoint = getBreakpoint(context);

    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        return basePadding * 0.8; // Tighter padding on mobile
      case ResponsiveBreakpoint.tablet:
        return basePadding;
      case ResponsiveBreakpoint.desktop:
        return basePadding * 1.2; // More spacious on desktop
    }
  }

  /// Should show numpad shortcuts (only on desktop/web)
  static bool shouldShowNumpadShortcuts(BuildContext context) {
    return isDesktop || isWeb;
  }

  /// Get appropriate button size based on platform
  static Size getResponsiveButtonSize(BuildContext context, Size baseSize) {
    final breakpoint = getBreakpoint(context);

    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        return Size(baseSize.width * 0.9, baseSize.height * 0.9);
      case ResponsiveBreakpoint.tablet:
        return baseSize;
      case ResponsiveBreakpoint.desktop:
        return Size(baseSize.width * 1.1, baseSize.height * 1.1);
    }
  }

  /// Get grid column count based on screen size
  static int getActionButtonColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 400) {
      return 2; // Very small screens
    } else if (width < 600) {
      return 3; // Mobile
    } else if (width < 900) {
      return 4; // Tablet
    } else {
      return 5; // Desktop
    }
  }
}

/// Responsive breakpoint enumeration
enum ResponsiveBreakpoint {
  mobile,
  tablet,
  desktop,
}

/// Navigation service for global context access
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
