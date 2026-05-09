// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';

import 'package:nutri_snap/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NutriSnapApp());
    await tester.pumpAndSettle(); // Wait for animations/loading

    // Verify that our app displays valid content
    expect(find.text('Home'), findsWidgets); // Bottom nav label
    expect(find.text('NutriBot'), findsWidgets); // Bottom nav label
  });
}
