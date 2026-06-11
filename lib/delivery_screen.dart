import 'package:flutter/material.dart';

class DeliveryScreen extends StatefulWidget {
  final bool hasActiveOrder;
  const DeliveryScreen({super.key, this.hasActiveOrder = false});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasActiveOrder) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Track Order", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining_outlined, size: 100, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              const Text(
                "No active orders to track",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              const Text(
                "Place an order to see it here!",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Column(
          children: [
            Text("Arriving in 12 mins", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Order #5589", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Animated Location Tracker (Blinkit Style Map)
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                image: const DecorationImage(
                  image: NetworkImage(
                    "https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop",
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.8,
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.location_on, color: Colors.blue, size: 40),
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: 250 - (150 * _animation.value),
                        left: 50 + (250 * _animation.value),
                        child: child!,
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              "assets/icons/Jaanu Farm's.jpeg",
                              height: 30,
                              width: 30,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 15,
                          color: Colors.yellow.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Delivery Info Card (Floating Style)
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ramesh is on his way", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Your delivery partner", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text("Expected by 7:45 AM", style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Order Tracking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  timelineStep("Order Placed", "7:30 AM", true),
                  timelineStep("Order Processed", "7:32 AM", true),
                  timelineStep("Out for Delivery", "7:35 AM", true, isLast: false, isCurrent: true),
                  timelineStep("Delivered", "Wait for it...", false, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget timelineStep(String title, String time, bool isDone, {bool isLast = false, bool isCurrent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 4) : null,
              ),
              child: isDone ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isDone ? Colors.black : Colors.grey)),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
