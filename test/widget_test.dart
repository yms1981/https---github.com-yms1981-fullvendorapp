// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:FullVendor/main.dart';
import 'package:FullVendor/utils/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    print((1).toStringWithoutRounding(3)); // 1
    print((4321.12345678).toStringWithoutRounding(3)); // 4321.123
    print((4321.12345678).toStringWithoutRounding(5)); // 4321.12346
    print((123456789012345).toStringWithoutRounding(3)); // 123456789012345
    print((10000000000000000).toStringWithoutRounding(4)); // 10000000000000000
    print((5.25).toStringWithoutRounding(0)); // 5
  });
}
