import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulated order data
    final List<Map<String, dynamic>> orders = [
      {
        "id": "ORD-5542",
        "date": "Oct 24, 2023",
        "items": "Cow Milk (2L)",
        "amount": "₹100",
        "status": "Delivered",
        "payment": "Paid (UPI)",
        "color": Colors.green,
      },
      {
        "id": "ORD-5589",
        "date": "Oct 26, 2023",
        "items": "Buffalo Milk (1L), Paneer (1 Pack)",
        "amount": "₹150",
        "status": "On the Way",
        "payment": "COD",
        "color": Colors.orange,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
      ),
      body: orders.isEmpty
          ? const Center(child: Text("You haven't placed any orders yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(order['date'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(order['items'], style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total: ${order['amount']}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: order['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order['status'],
                                style: TextStyle(color: order['color'], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.payment, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text("Payment: ${order['payment']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
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
