import 'package:flutter_test/flutter_test.dart';

import 'package:paigan/main.dart';
import 'package:paigan/services/app_state.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(PaiganApp(appState: appState));
    expect(find.text('ไปกัน'), findsWidgets);
  });
}