import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_digital_project/app/komi_app.dart';
import 'package:my_digital_project/features/auth/auth_choice_page.dart';
import 'package:my_digital_project/features/auth/login_page.dart';
import 'package:my_digital_project/features/auth/forgot_password_page.dart';
import 'package:my_digital_project/features/auth/reset_password_page.dart';
import 'package:my_digital_project/features/auth/signup_page.dart';
import 'package:my_digital_project/features/auth/welcome_page.dart';

void main() {
  testWidgets('Splash page shows loading text', (WidgetTester tester) async {
    await tester.pumpWidget(const KomiApp());

    expect(find.text('Chargement'), findsOneWidget);
  });

  for (final size in <Size>[
    const Size(320, 568),
    const Size(360, 640),
    const Size(360, 740),
    const Size(412, 914),
    const Size(414, 896),
    const Size(430, 932),
  ]) {
    testWidgets(
        'Auth screens render without overflow at ${size.width}x${size.height}',
        (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final page in const <Widget>[
        AuthChoicePage(),
        LoginPage(),
        SignUpPage(),
        WelcomePage(),
        ForgotPasswordPage(),
        ResetPasswordPage(token: 'test-token'),
      ]) {
        await tester.pumpWidget(
          const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SizedBox.shrink(),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: page,
          ),
        );
        await tester.pump(const Duration(milliseconds: 1200));

        expect(tester.takeException(), isNull);
      }
    });
  }
}
