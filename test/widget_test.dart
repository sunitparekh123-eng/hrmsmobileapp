import 'package:flutter_test/flutter_test.dart';

import 'package:hrms_mobile/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HRMSMobileApp());
    await tester.pump();
    expect(find.text('HRMS EMPLOYEE PORTAL'), findsOneWidget);
  });
}
