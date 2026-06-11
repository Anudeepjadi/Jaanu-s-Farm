import 'package:flutter/material.dart';

class ManageLoginsScreen extends StatefulWidget {
  const ManageLoginsScreen({super.key});

  @override
  State<ManageLoginsScreen> createState() => _ManageLoginsScreenState();
}

class _ManageLoginsScreenState extends State<ManageLoginsScreen> {
  final List<Map<String, String>> _users = [
    {"name": "Ramesh Kumar", "email": "ramesh@example.com", "role": "User", "lastLogin": "2 mins ago"},
    {"name": "Suresh Singh", "email": "suresh@example.com", "role": "User", "lastLogin": "1 hour ago"},
    {"name": "Admin User", "email": "admin@jaanu.farm", "role": "Admin", "lastLogin": "Just now"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Logins"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user['role'] == "Admin" ? Colors.blueGrey : Colors.green,
                child: Text(user['name']![0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${user['email']} • ${user['role']}"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Active", style: TextStyle(color: Colors.green, fontSize: 12)),
                  Text(user['lastLogin']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              onTap: () {
                // Show more user details or options to suspend/delete
              },
            ),
          );
        },
      ),
    );
  }
}
