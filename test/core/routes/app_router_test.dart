import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sout_salah/core/routes/app_router.dart';
import 'package:sout_salah/core/routes/app_routes.dart';

void main() {
  group('AppRouter', () {
    test('should return splash route for splash', () {
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.splash));
      expect(route, isA<PageRoute>());
      expect(route.settings.name, AppRoutes.splash);
    });

    test('should redirect home to login when unauthenticated', () {
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.home));
      expect(route, isA<PageRoute>());
      expect(route.settings.name, AppRoutes.login);
    });

    test('should redirect auth required routes to login when unauthenticated', () {
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.addMosque));
      expect(route, isA<PageRoute>());
      expect(route.settings.name, AppRoutes.login);
    });

    test('should return error route for unknown route', () {
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: '/unknown_route_xyz'));
      expect(route, isA<PageRoute>());
      // Error page doesn't have a specific name but it shouldn't be null
    });
  });
}
