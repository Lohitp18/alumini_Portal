import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PendingUsersPage extends StatefulWidget {
  @override
  _PendingUsersPageState createState() => _PendingUsersPageState();
}

class _PendingUsersPageState extends State<PendingUsersPage> {
  List users = [];

  @override
  void initState() {
    super.initState();
    fetchPendingUsers();
  }

  fetchPendingUsers() async {
    final response = await http.get(
      Uri.parse('http://localhost:5000/admin/users'),
      headers: {
        'Authorization': 'Bearer YOUR_ADMIN_JWT', // Replace with your token
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  approveUser(String id) async {
    await http.patch(
      Uri.parse('http://localhost:5000/admin/approve/$id'),
      headers: {'Authorization': 'Bearer YOUR_ADMIN_JWT'},
    );
    fetchPendingUsers();
  }

  rejectUser(String id) async {
    await http.patch(
      Uri.parse('http://localhost:5000/admin/reject/$id'),
      headers: {'Authorization': 'Bearer YOUR_ADMIN_JWT'},
    );
    fetchPendingUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pending Users')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(user['name']),
              subtitle: Text(user['email']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => approveUser(user['_id']),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => rejectUser(user['_id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
