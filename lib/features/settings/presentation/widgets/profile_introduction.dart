import 'package:gap/gap.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import 'profile_avatar.dart';

class ProfileIntroduction extends StatelessWidget {
  const ProfileIntroduction({required this.avatar, super.key});

  final String? avatar;

  @override
  Widget build(BuildContext context) => ReactiveValueListenableBuilder<String>(
    formControlName: 'agentName',
    builder: (context, name, _) => ReactiveValueListenableBuilder<String>(
      formControlName: 'nickname',
      builder: (context, nickname, _) {
        final entered = name.value?.trim() ?? '';
        final agentName = entered.isEmpty
            ? context.t.me.agentDefaultName
            : entered;
        final username = nickname.value?.trim() ?? '';
        final greeting = username.isEmpty
            ? context.t.me.profileGreeting(agentName: agentName)
            : context.t.me.profileGreetingNamed(
                username: username,
                agentName: agentName,
              );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: ProfileAvatar(
                key: const ValueKey('profile-introduction-avatar'),
                path: avatar,
                dimension: AppSizes.minTouchTarget,
              ),
            ),
            const Gap(AppSpacing.xs),
            Expanded(
              child: DecoratedBox(
                key: const ValueKey('profile-introduction-bubble'),
                decoration: BoxDecoration(
                  color: context.glass.bubbleOther,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xs),
                    topRight: Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(AppRadius.md),
                    bottomRight: Radius.circular(AppRadius.md),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    greeting,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.glass.onBubbleOther,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
