import 'package:flutter_test/flutter_test.dart';

import 'package:formless_example/main.dart';

void main() {
  testWidgets('app builds and shows Formless demo', (WidgetTester tester) async {
    await tester.pumpWidget(const FormlessExampleApp());

    expect(find.text('Formless'), findsWidgets);
    expect(find.textContaining('Formless widget'), findsOneWidget);
  });
}
