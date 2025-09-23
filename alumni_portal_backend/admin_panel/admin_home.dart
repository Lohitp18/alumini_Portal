import 'package:flutter/material.dart';
import 'pending_users.dart';
import 'pending_events.dart';
import 'pending_opportunities.dart';
import '../../lib/pages/pending_reports.dart';

class AdminHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              child: const Text('View Pending Users'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PendingUsersPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text('View Pending Events'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PendingEventsPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text('View Pending Opportunities'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PendingOpportunitiesPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text('View Reports'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PendingReportsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
