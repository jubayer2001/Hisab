import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/profile_providers.dart';
import '../../app/settings_providers.dart';
import '../../app/theme.dart';

/// The round profile icon: the first letter of the person's name, in their chosen colour,
/// with a small badge that says whether their data is backed up. Tapping opens Account.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, this.size = 40, this.onTap});

  final double size;

  /// Defaults to opening the Account screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.hisab;
    final name = ref.watch(userNameProvider).trim();
    final index = ref.watch(profileColorProvider);
    final badge = ref.watch(backupBadgeProvider);

    // The first colour is the app's own: soft teal with teal text, so it follows light and
    // dark mode. The others are solid with white text.
    final soft = index == 0;
    final background = soft ? scheme.primaryContainer : profileColors[index];
    final foreground = soft ? scheme.primary : Colors.white;

    final (badgeColor, badgeIcon, badgeInk) = switch (badge) {
      BackupBadge.none => (null, null, null),
      BackupBadge.unprotected => (colors.highlight, Icons.priority_high_rounded, const Color(0xFF2B1A00)),
      BackupBadge.protectedByGoogle => (colors.income, Icons.check_rounded, Colors.white),
      BackupBadge.waiting => (colors.highlight, Icons.cloud_off_rounded, const Color(0xFF2B1A00)),
    };
    final dot = size * 0.4;

    return Semantics(
      button: true,
      label: switch (badge) {
        BackupBadge.none => 'Profile',
        BackupBadge.unprotected => 'Profile. Not backed up',
        BackupBadge.protectedByGoogle => 'Profile. Backed up',
        BackupBadge.waiting => 'Profile. Backup waiting',
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => context.push('/account'),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: name.isEmpty
                    ? Icon(Icons.person_rounded, color: foreground, size: size * 0.55)
                    : Text(
                        name.characters.first.toUpperCase(),
                        style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: size * 0.45),
                      ),
              ),
              if (badgeColor != null)
                Positioned(
                  right: -size * 0.04,
                  bottom: -size * 0.04,
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: Icon(badgeIcon, size: dot * 0.65, color: badgeInk),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
