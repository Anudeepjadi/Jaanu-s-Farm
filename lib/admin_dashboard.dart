import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'login_screen.dart';
import 'manage_logins_screen.dart';
import 'firebase_service.dart';
import 'location_service.dart';
import 'delivery_screen.dart';

/// Admin dashboard with live Firebase orders and GPS broadcasting capability.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();

  // Currently active broadcasting order
  String? _broadcastingOrderId;
  StreamSubscription<Position>? _gpsSub;
  bool _isGpsActive = false;

  @override
  void dispose() {
    _stopBroadcasting();
    super.dispose();
  }

  Future<void> _startBroadcasting(String orderId) async {
    await _stopBroadcasting();

    final started = await LocationService.startTracking((Position pos) async {
      await _firebaseService.updateDeliveryPartnerLocation(
        orderId: orderId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    });

    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Cannot start tracking.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _firebaseService.updateOrderStatus(orderId, 'Picked Up');

    setState(() {
      _broadcastingOrderId = orderId;
      _isGpsActive = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('GPS broadcasting started!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopBroadcasting() async {
    if (_broadcastingOrderId != null) {
      await _firebaseService.clearDeliveryPartnerLocation(_broadcastingOrderId!);
    }
    await LocationService.stopTracking();
    await _gpsSub?.cancel();
    _gpsSub = null;
    if (mounted) {
      setState(() {
        _broadcastingOrderId = null;
        _isGpsActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Jaanu's Farm Admin",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isGpsActive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gps_fixed, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          IconButton(
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getAllOrders(),
        builder: (context, snapshot) {
          final allOrders = snapshot.data ?? [];
          final activeOrders = allOrders
              .where((o) => o['status'] != 'Delivered' && o['status'] != 'Cancelled')
              .toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Stats bar
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.blueGrey.shade900,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('${allOrders.length}', 'Orders', Icons.shopping_cart),
                      _statItem('Rs.${allOrders.fold<double>(0, (s, o) => s + ((o["total"] as num?)?.toDouble() ?? 0)).toStringAsFixed(0)}', 'Revenue', Icons.currency_rupee),
                      _statItem('${allOrders.where((o) => o["status"] == "Delivered").length}', 'Delivered', Icons.check_circle_outline),
                    ],
                  ),
                ),

                // Active GPS broadcast card
                if (_isGpsActive && _broadcastingOrderId != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade500],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Broadcasting Your Location',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                'Order #',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _stopBroadcasting,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Stop'),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Active Orders',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ManageLoginsScreen())),
                            child: const Text('Manage Users'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (activeOrders.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text('No active orders right now',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ...activeOrders.map((order) => _orderCard(order)),

                      if (allOrders.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('All Orders',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...allOrders
                            .where((o) => o['status'] == 'Delivered' || o['status'] == 'Cancelled')
                            .take(5)
                            .map((order) => _orderCard(order)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final String orderId = (order['id'] as String? ?? '');
    final String shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    final String status = order['status'] ?? 'Placed';
    final bool isActive = status != 'Delivered' && status != 'Cancelled';
    final bool isBroadcastingThis = _broadcastingOrderId == orderId;

    Color statusColor = Colors.orange;
    if (status == 'Delivered') statusColor = Colors.green;
    if (status == 'Cancelled') statusColor = Colors.red;
    if (status == 'On the Way') statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        border: isBroadcastingThis
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ORD-$shortId',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status,
                      style: TextStyle(color: statusColor,
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(order['address'] ?? 'No address',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text('Rs.',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statusButton(orderId, status),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryScreen(
                            orderId: orderId,
                            customerLat: (order['latitude'] as num?)?.toDouble() ?? 17.3850,
                            customerLng: (order['longitude'] as num?)?.toDouble() ?? 78.4867,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('View Map'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: isBroadcastingThis
                        ? ElevatedButton.icon(
                            onPressed: _stopBroadcasting,
                            icon: const Icon(Icons.gps_off, size: 16),
                            label: const Text('Stop GPS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _startBroadcasting(orderId),
                            icon: const Icon(Icons.gps_fixed, size: 16),
                            label: const Text('Start GPS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String orderId, String currentStatus) {
    final statuses = ['Placed', 'Processing', 'Picked Up', 'On the Way', 'Delivered'];
    final currentIdx = statuses.indexOf(currentStatus);
    final nextStatus = (currentIdx >= 0 && currentIdx < statuses.length - 1)
        ? statuses[currentIdx + 1]
        : null;

    if (nextStatus == null) return const SizedBox.shrink();

    return OutlinedButton(
      onPressed: () => _firebaseService.updateOrderStatus(orderId, nextStatus),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text('Mark: $nextStatus',
          style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

