import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nurai/features/companion/minute_reflection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreenAtSize(
    WidgetTester tester,
    Size size, {
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: const MinuteReflectionScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders without layout errors on a compact iPhone',
      (tester) async {
    await pumpScreenAtSize(tester, const Size(375, 667));

    expect(find.text('Bir Dakika Tefekkür'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without layout errors on a large iPhone',
      (tester) async {
    await pumpScreenAtSize(tester, const Size(430, 932));

    expect(find.text('Bir Dakika Tefekkür'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports dark mode and large accessibility text',
      (tester) async {
    await pumpScreenAtSize(
      tester,
      const Size(430, 932),
      theme: ThemeData.dark(useMaterial3: true),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(find.text('Bir Dakika Tefekkür'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
