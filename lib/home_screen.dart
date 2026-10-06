import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_screen.dart';
import 'delivery_screen.dart';
import 'location_picker_screen.dart';
import 'orders_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'firebase_service.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'providers/payment_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? name;
  const HomeScreen({super.key, this.name});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _activeOrderId;           // tracks the latest active order's Firebase key
  double? _activeOrderLat;          // customer lat saved with the order
  double? _activeOrderLng;          // customer lng saved with the order
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _checkActiveOrders();
  }

  void _checkActiveOrders() {
    _firebaseService.getOrders().listen((orders) {
      if (mounted) {
        final active = orders.where((o) =>
          o['status'] != 'Delivered' && o['status'] != 'Cancelled').toList();
        setState(() {
          if (active.isNotEmpty) {
            _activeOrderId = active.first['id'] as String?;
            _activeOrderLat = (active.first['latitude'] as num?)?.toDouble();
            _activeOrderLng = (active.first['longitude'] as num?)?.toDouble();
          } else {
            _activeOrderId = null;
          }
        });
      }
    }, onError: (error) {
      debugPrint("Error listening to active orders: $error");
    });
  }

  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);

    final List<Widget> screens = [
      ShopView(
        name: widget.name,
        onViewCart: () => _switchToTab(3),
      ),
      const OrdersScreen(),
      _activeOrderId != null
          ? DeliveryScreen(
              orderId: _activeOrderId!,
              customerLat: _activeOrderLat ?? 17.3850,
              customerLng: _activeOrderLng ?? 78.4867,
              onBackPressed: () => _switchToTab(0),
            )
          : const _NoActiveOrderPlaceholder(),
      CartScreen(
        onOrderConfirmed: () async {
          final itemsSnapshot = List<Map<String, dynamic>>.from(cartItems);
          final double grandTotal = ref.read(cartProvider.notifier).grandTotal;
          final locationState = ref.read(locationProvider);
          final address = locationState.address;
          final latLng = locationState.coordinates;

          // Clear cart & switch tab IMMEDIATELY
          ref.read(cartProvider.notifier).clearCart();
          _switchToTab(2); 

          // Save order to Firebase and capture the orderId
          final orderId = await _firebaseService.saveOrder(
            itemsSnapshot,
            grandTotal,
            address,
            lat: latLng?.latitude,
            lng: latLng?.longitude,
          );
          if (orderId != null && mounted) {
            setState(() {
              _activeOrderId = orderId;
              _activeOrderLat = latLng?.latitude;
              _activeOrderLng = latLng?.longitude;
            });
          }
        },
      ),
      ProfileScreen(name: widget.name),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _switchToTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: "Orders"),
          const BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_outlined), activeIcon: Icon(Icons.delivery_dining), label: "Tracking"),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text("${cartItems.length}"),
              isLabelVisible: cartItems.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              label: Text("${cartItems.length}"),
              isLabelVisible: cartItems.isNotEmpty,
              child: const Icon(Icons.shopping_cart),
            ),
            label: "Cart",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class ShopView extends ConsumerStatefulWidget {
  final String? name;
  final VoidCallback onViewCart;

  const ShopView({super.key, this.name, required this.onViewCart});

  @override
  ConsumerState<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends ConsumerState<ShopView> {
  String searchQuery = "";
  bool _isLoadingProducts = true;
  List<Map<String, String>> allProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    // Simulating network delay for Firebase fetch
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        allProducts = [
          {"title": "Cow Milk", "image": "assets/images/cow_milk.png", "price": "₹50", "desc": "Pure Cow Milk - 500ml", "tag": "Best Seller"},
          {"title": "Buffalo Milk", "image": "assets/images/buffalo_milk.png", "price": "₹60", "desc": "Fresh Buffalo Milk - 500ml", "tag": "High Protein"},
          {"title": "Organic Milk", "image": "assets/images/organic_milk.png", "price": "₹70", "desc": "Pure Organic Milk - 500ml", "tag": "Organic"},
          {"title": "Paneer", "image": "assets/images/paneer.png", "price": "₹90", "desc": "Fresh Cottage Cheese - 200g", "tag": "Fresh"},
        ];
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _updateLocation() async {
    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );
    if (result != null && mounted) {
      ref.read(locationProvider.notifier).updateLocation(result);
    }
  }

  void _getCurrentLocation() {
    ref.read(locationProvider.notifier).refreshCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredProducts = allProducts
        .where((p) => p['title']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
        
    final locationState = ref.watch(locationProvider);
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.read(cartProvider.notifier).itemTotal;
    final totalItems = cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
            // APP BAR
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black12,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _updateLocation,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFFE94E1B), size: 28),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text("Delivery in 10 mins", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
                                        Icon(Icons.keyboard_arrow_down, size: 22, color: Colors.black87),
                                      ],
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      child: Text(
                                        locationState.address, 
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13), 
                                        overflow: TextOverflow.ellipsis
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _getCurrentLocation,
                            child: CircleAvatar(
                              backgroundColor: Colors.grey.shade100,
                              radius: 20,
                              child: locationState.isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: "Search for milk, paneer, ghee...",
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (filteredProducts.isEmpty)
              const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(50), child: Text("No items found 🥛", style: TextStyle(fontSize: 16, color: Colors.grey)))),
              ),

            if (searchQuery.isEmpty) ...[
              // PROMO BANNER
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.electric_moped, color: Color(0xFFE65100), size: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Hyper-local Delivery", style: TextStyle(color: Color(0xFFE65100), fontSize: 18, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text("Fresh from farm to your door in 10 mins.", style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CATEGORIES
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text("Shop by Category", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          categoryItem("Milk", Icons.local_drink, Colors.blue.shade50, Colors.blue),
                          categoryItem("Curd", Icons.opacity, Colors.pink.shade50, Colors.pink),
                          categoryItem("Paneer", Icons.bakery_dining, Colors.orange.shade50, Colors.orange),
                          categoryItem("Ghee", Icons.water_drop, Colors.amber.shade50, Colors.amber.shade700),
                          categoryItem("Cheese", Icons.grid_view_rounded, Colors.green.shade50, Colors.green),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text("Bestsellers", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
                ),
              ),
            ],

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_isLoadingProducts) {
                      return shimmerCard();
                    }
                    final product = filteredProducts[index];
                    return milkCard(product, ref);
                  },
                  childCount: _isLoadingProducts ? 4 : filteredProducts.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: totalItems > 0 ? 100 : 30)),
          ],
        ),
        
        // Persistent Cart Snackbar (Blinkit style)
        if (totalItems > 0)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: widget.onViewCart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$totalItems Items", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text("₹$cartTotal", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const Row(
                      children: [
                        Text("View Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  ),
);
  }

  Widget categoryItem(String title, IconData icon, Color bgColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 50, height: 10, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 10, color: Colors.white),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 40, height: 16, color: Colors.white),
                      Container(
                        width: 60, height: 28,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget milkCard(Map<String, String> product, WidgetRef ref) {
    final title = product['title']!;
    final imagePath = product['image']!;
    final price = product['price']!;
    final desc = product['desc']!;
    final tag = product['tag']!;

    final cartItems = ref.watch(cartProvider);
    int cartIndex = cartItems.indexWhere((item) => item['title'] == title);
    int qty = cartIndex != -1 ? cartItems[cartIndex]['quantity'] : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text("10 MINS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87)),
                        if (qty == 0)
                          GestureDetector(
                            onTap: () {
                              ref.read(cartProvider.notifier).addToCart(title, price, imagePath);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Added $title to Cart 🥛"), duration: const Duration(milliseconds: 600)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.green.shade700, width: 1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text("ADD", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w800, fontSize: 12)),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(cartIndex, -1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Icon(Icons.remove, color: Colors.white, size: 16),
                                  ),
                                ),
                                Text("$qty", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                InkWell(
                                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(cartIndex, 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tag.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(11), bottomRight: Radius.circular(8)),
                ),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

class CartScreen extends ConsumerStatefulWidget {
  final VoidCallback onOrderConfirmed;
  const CartScreen({
    super.key,
    required this.onOrderConfirmed,
  });

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String _paymentMethod = "UPI";

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final locationState = ref.watch(locationProvider);
    double itemTotal = ref.read(cartProvider.notifier).itemTotal;
    double grandTotal = ref.read(cartProvider.notifier).grandTotal;

    final isProcessingPayment = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty! 🥛"))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text("Delivering to Home", style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(width: 5),
                                      Icon(Icons.verified, color: Colors.blue, size: 14),
                                    ],
                                  ),
                                  Text(locationState.address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            TextButton(onPressed: () {}, child: Text("CHANGE", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: cartItems.asMap().entries.map((entry) {
                            int index = entry.key;
                            var item = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Icon(Icons.shopping_basket, color: Theme.of(context).colorScheme.primary, size: 24)
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(item['price']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.remove, size: 16),
                                          onPressed: () => ref.read(cartProvider.notifier).updateQuantity(index, -1),
                                        ),
                                        Text("${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.add, size: 16, color: Colors.green),
                                          onPressed: () => ref.read(cartProvider.notifier).updateQuantity(index, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            RadioGroup<String>(
                              groupValue: _paymentMethod,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _paymentMethod = val);
                                }
                              },
                              child: Column(
                                children: [
                                  paymentOption("UPI (GPay, PhonePe)", Icons.account_balance_wallet, "UPI"),
                                  paymentOption("Cards (Credit/Debit)", Icons.credit_card, "Card"),
                                  paymentOption("Net Banking", Icons.account_balance, "NetBank"),
                                  paymentOption("Cash on Delivery (COD)", Icons.money, "COD"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Bill Details", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            billRow("Item Total", "₹$itemTotal"),
                            billRow("Delivery Fee", "₹15"),
                            billRow("Handling Charge", "₹2"),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("₹$grandTotal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Extra space for bottom button
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("₹$grandTotal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            Text("VIEW DETAILED BILL", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isProcessingPayment ? null : () async {
                            await ref.read(paymentProvider.notifier).processPayment(
                              amount: grandTotal,
                              method: _paymentMethod,
                              onSuccess: () => showOrderSuccessDialog(grandTotal),
                              onError: (err) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: isProcessingPayment 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Confirm Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Icon(Icons.keyboard_arrow_right, color: Colors.white),
                              ],
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget paymentOption(String title, IconData icon, String value) {
    return RadioListTile<String>(
      title: Text(title),
      secondary: Icon(icon, color: Colors.grey),
      value: value,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget billRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void showOrderSuccessDialog(double grandTotal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/animations/Milk.json', height: 120, repeat: false),
            const SizedBox(height: 10),
            const Text("Order Placed!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Payment of ₹$grandTotal via $_paymentMethod was successful.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop Dialog
                widget.onOrderConfirmed(); // Call callback to clear cart and switch tab
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, minimumSize: const Size(double.infinity, 50)),
              child: const Text("Track Order Now", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveOrderPlaceholder extends StatelessWidget {
  const _NoActiveOrderPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Order", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delivery_dining,
                    size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 28),
              Text(
                "No Active Orders",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Place an order and you'll be able to\ntrack your delivery here in real-time.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
