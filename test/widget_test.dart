import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_shop_uet/main.dart';

void main() {
  testWidgets('UET Shops login screen loads', (tester) async {
    await tester.pumpWidget(const UetShopsApp());
    await tester.pumpAndSettle();
    expect(find.text('UET Shops'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
