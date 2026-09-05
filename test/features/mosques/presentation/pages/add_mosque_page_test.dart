import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import 'package:sout_salah/core/utils/permission_checker.dart';
import 'package:sout_salah/features/mosques/presentation/pages/add_mosque_page.dart';

class MockAppLogger implements AppLogger {
  bool infoCalled = false;
  
  @override
  void d(String message, [dynamic error, StackTrace? stackTrace]) {}

  @override
  void e(String message, [dynamic error, StackTrace? stackTrace]) {}

  @override
  void f(String message, [dynamic error, StackTrace? stackTrace]) {}

  @override
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    infoCalled = true;
  }

  @override
  void t(String message, [dynamic error, StackTrace? stackTrace]) {}

  @override
  void w(String message, [dynamic error, StackTrace? stackTrace]) {}
}

class MockPermissionChecker implements PermissionChecker {
  @override
  Future<bool> canAddMosque() async => true;

  @override
  Future<bool> isSuperAdmin() async => false;
  
  @override
  Future<bool> canReviewRequests() async => false;
  
  @override
  Future<bool> hasPermission(String permission) async => false;
  
  @override
  Future<bool> canShowDeleteButton(String recordingId, String mosqueId) async => false;

  @override
  Future<bool> canShowManagePublishersButton(String mosqueId) async => false;

  @override
  Future<bool> canShowUploadButton(String mosqueId) async => false;

  @override
  Future<bool> isAdminOfMosque(String mosqueId) async => false;
}

void main() {
  late MockAppLogger mockLogger;

  setUp(() {
    mockLogger = MockAppLogger();
    GetIt.I.registerSingleton<AppLogger>(mockLogger);
  });

  tearDown(() {
    GetIt.I.unregister<AppLogger>();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        permissionCheckerProvider.overrideWithValue(MockPermissionChecker()),
      ],
      child: const MaterialApp(
        home: AddMosquePage(),
      ),
    );
  }

  testWidgets('displays form fields correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('إضافة مسجد جديد'), findsOneWidget);
    expect(find.text('اسم المسجد'), findsOneWidget);
    expect(find.text('عنوان المسجد (اختياري / يُضاف تلقائياً)'), findsOneWidget);
    expect(find.text('الوصف (اختياري)'), findsOneWidget);
    expect(find.text('إرسال طلب إضافة'), findsOneWidget);
    
    expect(mockLogger.infoCalled, isTrue); // Should log on init
  });
}
