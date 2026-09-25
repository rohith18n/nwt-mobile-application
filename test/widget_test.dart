// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  testWidgets('Basic widget test scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        designSize: const Size(432.0, 960.0),
        child: const MaterialApp(
          home: Scaffold(body: Text('ok')),
        ),
      ),
    );

    expect(find.text('ok'), findsOneWidget);
  });
}
