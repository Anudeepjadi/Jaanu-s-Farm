import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'manage_logins_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Jaanu's Farm Admin", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Quick Stats
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.blueGrey.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  statItem("124", "Orders", Icons.shopping_cart),
                  statItem("₹45k", "Revenue", Icons.currency_rupee),
                  statItem("98", "Users", Icons.people),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Active Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageLoginsScreen())),
                        child: const Text("Manage Users"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  orderCard("ORD-1024", "Ramesh Kumar", "₹180", "On the Way", Colors.orange, "Paid"),
                  orderCard("ORD-1025", "Suresh Singh", "₹120", "Pending", Colors.red, "COD"),
                  orderCard("ORD-1026", "Amit Patel", "₹90", "Processing", Colors.blue, "Paid"),
                  orderCard("ORD-1027", "Priya Sharma", "₹240", "Delivered", Colors.green, "COD"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget orderCard(String id, String name, String amount, String status, Color color, String payType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.payment, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text("Payment: $payType", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              const Text("Update Status", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
