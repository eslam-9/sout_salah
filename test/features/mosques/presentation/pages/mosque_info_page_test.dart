import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:sout_salah/core/utils/app_logger.dart';
import 'package:sout_salah/features/mosques/domain/entities/mosque.dart';
import 'package:sout_salah/features/mosques/presentation/pages/mosque_info_page.dart';

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

void main() {
  late MockAppLogger mockLogger;

  setUp(() {
    mockLogger = MockAppLogger();
    GetIt.I.registerSingleton<AppLogger>(mockLogger);
  });

  tearDown(() {
    GetIt.I.unregister<AppLogger>();
  });

  Widget createWidgetUnderTest(Mosque mosque) {
    return ProviderScope(
      child: MaterialApp(
        home: MosqueInfoPage(mosque: mosque),
      ),
    );
  }

  testWidgets('displays mosque name correctly', (WidgetTester tester) async {
    const testMosque = Mosque(
      id: '1',
      name: 'Test Mosque',
      adminId: 'admin1',
    );

    await tester.pumpWidget(createWidgetUnderTest(testMosque));
    await tester.pumpAndSettle();

    expect(find.text('Test Mosque'), findsOneWidget);
    expect(mockLogger.infoCalled, isTrue); // Should log on init
  });

  testWidgets('shows no extra info message when no location or description provided', (WidgetTester tester) async {
    const testMosque = Mosque(
      id: '1',
      name: 'Test Mosque',
      adminId: 'admin1',
    );

    await tester.pumpWidget(createWidgetUnderTest(testMosque));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد معلومات إضافية لهذا المسجد.'), findsOneWidget);
  });

  testWidgets('shows location text when provided', (WidgetTester tester) async {
    const testMosque = Mosque(
      id: '1',
      name: 'Test Mosque',
      adminId: 'admin1',
      location: 'Test Location',
    );

    await tester.pumpWidget(createWidgetUnderTest(testMosque));
    await tester.pumpAndSettle();

    expect(find.text('Test Location'), findsOneWidget);
    expect(find.text('لا توجد معلومات إضافية لهذا المسجد.'), findsNothing);
  });
}
