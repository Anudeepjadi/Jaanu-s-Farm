import 'package:flutter/material.dart';
import 'manage_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'orders_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? name;
  const ProfileScreen({super.key, this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name ?? "Guest User",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "jaanu.farms@example.com",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const Divider(),
            profileOption(context, Icons.shopping_bag, "My Orders", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            }),
            profileOption(context, Icons.location_on, "Manage Addresses", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageAddressesScreen()),
              );
            }),
            profileOption(context, Icons.payment, "Payment Methods", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
              );
            }),
            profileOption(context, Icons.notifications, "Notifications", () {}),
            profileOption(context, Icons.settings, "Settings", () {}),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget profileOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
