import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../utils/app_logger.dart';

/// Centralized navigation service for programmatic navigation
///
/// This service provides type-safe navigation methods that can be used
/// from business logic (providers, notifiers) without direct BuildContext access.
class NavigationService {
  /// Global navigator key for accessing navigator state
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate to a named route
  ///
  /// Returns the result from the pushed route when it's popped
  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    GetIt.I<AppLogger>().i('🧭 NavigationService: Navigating to $routeName');
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Pop the current route
  ///
  /// Optionally pass a result back to the previous route
  static void goBack<T>([T? result]) {
    GetIt.I<AppLogger>().i('🧭 NavigationService: Going back');
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop(result);
    }
  }

  /// Replace the current route with a new route
  ///
  /// The current route is removed from the navigation stack
  static Future<T?> navigateAndReplace<T>(
    String routeName, {
    Object? arguments,
  }) {
    GetIt.I<AppLogger>().i('🧭 NavigationService: Replacing with $routeName');
    return navigatorKey.currentState!.pushReplacementNamed<T, dynamic>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to a route and remove all previous routes until predicate returns true
  ///
  /// Useful for authentication flows where you want to clear the navigation stack
  static Future<T?> navigateAndRemoveUntil<T>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    GetIt.I<AppLogger>().i(
      '🧭 NavigationService: Navigating to $routeName and removing until predicate',
    );
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Check if the navigator can pop
  static bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  /// Get the current route name
  static String? getCurrentRoute() {
    String? currentRoute;
    navigatorKey.currentState?.popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });
    return currentRoute;
  }
}
