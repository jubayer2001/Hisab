import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nothing here yet',
        message: 'Every expense and income you add will be listed here, grouped by day.',
      ),
    );
  }
}
