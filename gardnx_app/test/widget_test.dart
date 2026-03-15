import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gardnx_app/app.dart';

void main() {
  testWidgets('GardNxApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GardNxApp()),
    );
    // Just verify the app widget mounts successfully.
    expect(find.byType(GardNxApp), findsOneWidget);
  });
}
