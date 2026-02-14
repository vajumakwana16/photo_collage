import 'package:flutter_test/flutter_test.dart';
import 'package:photo_collage/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoCollageApp());
    expect(find.text('Photo Collage Demo'), findsOneWidget);
  });
}
