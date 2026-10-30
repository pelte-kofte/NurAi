import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nurai/features/companion/minute_reflection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreenAtSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      const MaterialApp(home: MinuteReflectionScreen()),
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
}
