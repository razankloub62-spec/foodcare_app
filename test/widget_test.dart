import 'package:flutter_test/flutter_test.dart';
import 'package:uni/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodCareApp());
  });
}