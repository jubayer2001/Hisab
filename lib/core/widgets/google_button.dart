import 'package:flutter/material.dart';

/// "Sign in with Google": a plain outlined button with the blue G, used on the welcome step
/// and on the Account screen so both look the same.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
      onPressed: onPressed,
      // Scales down instead of overflowing on a narrow screen or with a large system font.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(width: 10),
            Text('Sign in with Google', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
