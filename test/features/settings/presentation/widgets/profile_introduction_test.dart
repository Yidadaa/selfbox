import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/settings/presentation/widgets/profile_introduction.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  for (final locale in AppLocale.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'introduction follows draft names and fits narrow layout in $locale/$brightness',
        (tester) async {
          final form = FormGroup({
            'agentName': FormControl<String>(value: ''),
            'nickname': FormControl<String>(value: ''),
          });
          addTearDown(form.dispose);
          await tester.pumpPage(
            ReactiveForm(
              formGroup: form,
              child: const Center(
                child: SizedBox(
                  width: 248,
                  child: ProfileIntroduction(avatar: null),
                ),
              ),
            ),
            locale: locale,
            brightness: brightness,
          );
          expect(
            find.text(t.me.profileGreeting(agentName: t.me.agentDefaultName)),
            findsOneWidget,
          );
          form.control('agentName').value = 'Momo';
          form.control('nickname').value = 'Flynn';
          await tester.pumpAndSettle();
          expect(
            find.text(
              t.me.profileGreetingNamed(username: 'Flynn', agentName: 'Momo'),
            ),
            findsOneWidget,
          );
          final avatar = tester.getRect(
            find.byKey(const ValueKey('profile-introduction-avatar')),
          );
          final bubble = tester.getRect(
            find.byKey(const ValueKey('profile-introduction-bubble')),
          );
          expect(avatar.right, lessThan(bubble.left));
          expect(
            bubble.right,
            lessThanOrEqualTo(
              tester.getRect(find.byType(ProfileIntroduction)).right,
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
