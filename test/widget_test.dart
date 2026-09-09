import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_mobile/main.dart';

void main() {
  testWidgets('application opens splash then login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CarRentalApp());

    expect(find.text('CAR RENTAL'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
