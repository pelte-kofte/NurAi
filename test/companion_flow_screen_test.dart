import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nurai/features/companion/companion_flow_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('intent picker is text-only and avoids template copy',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const CompanionFlowScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Icon), findsNothing);
    expect(find.textContaining('Seçimine göre'), findsNothing);
    expect(find.textContaining('duruş'), findsNothing);
    expect(find.text('Şu an seni en çok ne meşgul ediyor?'), findsOneWidget);
    expect(find.text('Aklım çok dolu'), findsOneWidget);
    expect(find.byType(CupertinoPicker), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
