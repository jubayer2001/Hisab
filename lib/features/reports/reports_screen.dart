import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const EmptyState(
        icon: Icons.insert_chart_outlined,
        title: 'No data to show yet',
        message: 'Charts for your day, week, month and year appear once you add expenses.',
      ),
    );
  }
}
