import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pages/home.dart';
import 'pages/alumini.dart';
import 'pages/opportunities.dart';
import 'pages/event.dart';
import 'pages/institution.dart';
import 'profile_page.dart';
import 'pages/admin.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    AlumniPage(),
    OpportunitiesPage(),
    EventsPage(),
    InstitutionsPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, size: 40);
              },
            ),
            const SizedBox(width: 10),
            const Text('Alumni Portal'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                  break;
                case 'admin':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPage()),
                  );
                  break;
                case 'signout':
                  const storage = FlutterSecureStorage();
                  await storage.delete(key: 'auth_token');
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'admin', child: Text('Admin')),
              const PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Alumni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Opportunities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Institutions',
          ),
        ],
      ),
    );
  }
}
