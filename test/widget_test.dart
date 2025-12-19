import 'package:flutter_test/flutter_test.dart';
import 'package:my_digital_project/main.dart';

void main() {
  testWidgets('Home page shows welcome text', (WidgetTester tester) async {
    // Lancer l'application
    await tester.pumpWidget(const MyDigitalProjectApp());

    // Vérifier que le texte est affiché
    expect(find.textContaining('Bienvenue sur'), findsOneWidget);
  });
}
