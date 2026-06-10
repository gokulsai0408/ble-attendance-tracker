import 'package:flutter_test/flutter_test.dart';

import 'package:ble_attendance_tracker/main.dart';

void main() {
  testWidgets('shows role selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('BLE Attendance'), findsOneWidget);
    expect(find.text('I am a Student'), findsOneWidget);
    expect(find.text('I am a Professor'), findsOneWidget);
  });
}
