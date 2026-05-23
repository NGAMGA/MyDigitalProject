import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_explorer/main.dart';

void main() {
  testWidgets('Meal Explorer app starts', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');

    await tester.pumpWidget(const MealExplorerApp());

    expect(find.text('Meal Explorer'), findsOneWidget);
    expect(find.text('Recherche'), findsWidgets);
  });
}
