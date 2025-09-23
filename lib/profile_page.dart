import 'package:flutter/material.dart';
import 'pages/connections.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConnectionsPage()),
                );
              },
              icon: const Icon(Icons.group),
              label: const Text('Connections'),
            ),
          ],
        ),
      ),
    );
  }
}
