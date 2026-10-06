import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'manage_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'orders_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? name;
  const ProfileScreen({super.key, this.name});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _name;
  String? _email;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _email = user.email;
          _name = widget.name ?? user.email?.split('@')[0];
        });
      }

      try {
        final profile = await _firebaseService.getUserProfile(user.uid).timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        
        if (profile != null && mounted) {
          setState(() {
            if (profile['name'] != null && profile['name'].toString().isNotEmpty) {
              _name = profile['name'].toString();
            }
            if (profile['email'] != null && profile['email'].toString().isNotEmpty) {
              _email = profile['email'].toString();
            }
          });
        }
      } catch (e) {
        debugPrint("Error loading profile data: $e");
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    children: [
                      Text(
                        _name ?? "Guest User",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _email ?? "",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
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
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
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
