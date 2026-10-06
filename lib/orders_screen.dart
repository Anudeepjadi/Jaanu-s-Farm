import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'delivery_screen.dart';
import 'providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(ordersStreamProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Active"),
              Tab(text: "Delivered"),
              Tab(text: "Cancelled"),
            ],
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: ordersAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.orange),
                  const SizedBox(height: 12),
                  const Text(
                    "Unable to load orders right now",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Please check your connection or sign in again.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (allOrders) {
            if (allOrders.isEmpty) {
              return const Center(child: Text("You haven't placed any orders yet. 🥛"));
            }

            // Sort orders by timestamp (newest first)
            final sortedOrders = List<Map<String, dynamic>>.from(allOrders);
            sortedOrders.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

            return TabBarView(
              children: [
                _buildOrderList(context, sortedOrders.where((o) => 
                  o['status'] != 'Delivered' && o['status'] != 'Cancelled').toList()),
                _buildOrderList(context, sortedOrders.where((o) => o['status'] == 'Delivered').toList()),
                _buildOrderList(context, sortedOrders.where((o) => o['status'] == 'Cancelled').toList()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("No orders in this category", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final String fullOrderId = (order['id'] as String? ?? "Unknown");
        final String orderId = fullOrderId.length > 8 ? fullOrderId.substring(0, 8).toUpperCase() : fullOrderId.toUpperCase();
        
        int timestamp = 0;
        if (order['timestamp'] is int) {
          timestamp = order['timestamp'];
        } else if (order['timestamp'] is Map) {
          timestamp = DateTime.now().millisecondsSinceEpoch;
        }
        
        final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final String formattedDate = DateFormat('MMM dd, hh:mm a').format(date);
        
        String itemsSummary = "";
        if (order['items'] is List) {
          itemsSummary = (order['items'] as List)
              .map((item) => "${item['quantity'] ?? 1}x ${item['title']}")
              .join(", ");
        }

        Color statusColor = Colors.orange;
        if (order['status'] == 'Delivered') statusColor = Colors.green;
        if (order['status'] == 'Cancelled') statusColor = Colors.red;
        if (order['status'] == 'On the Way') statusColor = Colors.blue;
        if (order['status'] == 'Picked Up') statusColor = Colors.deepPurple;

        return Card(
          elevation: 2,
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
                    Text("ORD-$orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Divider(height: 20),
                Text(itemsSummary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total: ₹${order['total']}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order['status'] ?? 'Placed',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        order['address'] ?? "No address", 
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (order['status'] != 'Delivered' && order['status'] != 'Cancelled')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryScreen(
                              orderId: fullOrderId,
                              customerLat: (order['latitude'] as num?)?.toDouble() ?? 17.3850,
                              customerLng: (order['longitude'] as num?)?.toDouble() ?? 78.4867,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.gps_fixed, size: 16),
                        label: const Text('Track Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
