import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'delivery_screen.dart';
import 'location_service.dart';
import 'location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  final String? name;
  const HomeScreen({super.key, this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasActiveOrder = false;
  String _currentAddress = "123, Green Farm Road, Mumbai";
  final List<Map<String, String>> cartItems = [];

  Future<void> _updateLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Simulate getting address from LatLng
      // In a real app, you'd use geocoding here
      // But for now let's just use the service we created
      try {
        final address = await LocationService.getAddressFromLatLng(
          Position(
            latitude: result.latitude,
            longitude: result.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          ),
        );
        setState(() {
          _currentAddress = address;
        });
      } catch (e) {
        setState(() {
          _currentAddress = "${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}";
        });
      }

      if (mounted) Navigator.pop(context);
    }
  }

  void addToCart(String title, String price, String imagePath) {
    setState(() {
      cartItems.add({
        "title": title,
        "price": price,
        "image": imagePath,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added $title to Cart 🥛 "),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _clearCart() {
    setState(() {
      cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ShopView(
        name: widget.name, 
        onAddToCart: addToCart, 
        currentAddress: _currentAddress,
        onUpdateLocation: _updateLocation,
      ),
      DeliveryScreen(hasActiveOrder: _hasActiveOrder),
      CartScreen(
        cartItems: cartItems, 
        currentAddress: _currentAddress,
        onOrderConfirmed: () {
          _clearCart();
          setState(() {
            _hasActiveOrder = true;
          });
          _switchToTab(1); // Switch to Tracking tab
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

class ShopView extends StatefulWidget {
  final String? name;
  final Function(String, String, String) onAddToCart;
  final String currentAddress;
  final VoidCallback onUpdateLocation;

  const ShopView({
    super.key, 
    this.name, 
    required this.onAddToCart,
    required this.currentAddress,
    required this.onUpdateLocation,
  });

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  String searchQuery = "";
  final List<Map<String, String>> allProducts = [
    {"title": "Cow Milk", "image": "assets/images/cow_milk.png", "price": "₹50", "desc": "Pure Cow Milk - 500ml"},
    {"title": "Buffalo Milk", "image": "assets/images/buffalo_milk.png", "price": "₹60", "desc": "Fresh Buffalo Milk - 500ml"},
    {"title": "Organic Milk", "image": "assets/images/organic_milk.png", "price": "₹70", "desc": "Pure Organic Milk - 500ml"},
    {"title": "Paneer", "image": "assets/images/paneer.png", "price": "₹90", "desc": "Fresh Cottage Cheese - 200g"},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredProducts = allProducts
        .where((p) => p['title']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: widget.onUpdateLocation,
                        child: Row(
                          children: [
                            Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Delivery Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(widget.currentAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: "Search 'Paneer', 'Milk'...",
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (filteredProducts.isEmpty)
              const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(50), child: Text("No items found 🥛"))),
              ),

            if (searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      categoryItem("Milk", Icons.local_drink),
                      categoryItem("Curd", Icons.opacity),
                      categoryItem("Paneer", Icons.bakery_dining),
                      categoryItem("Ghee", Icons.water_drop),
                      categoryItem("Cheese", Icons.grid_view_rounded),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(0.7), Theme.of(context).colorScheme.primary]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.yellow, size: 40),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("10 Min Delivery!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Fresh from our farm to your door.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = filteredProducts[index];
                    return milkCard(product['title']!, product['image']!, product['price']!, product['desc']!);
                  },
                  childCount: filteredProducts.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget categoryItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget milkCard(String title, String imagePath, String price, String desc) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 10), maxLines: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    GestureDetector(
                      onTap: () => widget.onAddToCart(title, price, imagePath),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          border: Border.all(color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("ADD", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  final List<Map<String, String>> cartItems;
  final VoidCallback onOrderConfirmed;
  final String currentAddress;
  const CartScreen({
    super.key, 
    required this.cartItems, 
    required this.onOrderConfirmed,
    required this.currentAddress,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _paymentMethod = "UPI";

  @override
  Widget build(BuildContext context) {
    double itemTotal = widget.cartItems.length * 50.0;
    double grandTotal = itemTotal > 0 ? itemTotal + 15 + 2 : 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: widget.cartItems.isEmpty
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
                                  Text(widget.currentAddress, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: widget.cartItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(width: 30, height: 30, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(5)), child: Icon(Icons.shopping_basket, color: Theme.of(context).colorScheme.primary, size: 18)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text(item['price']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )).toList(),
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
                            paymentOption("UPI (GPay, PhonePe)", Icons.account_balance_wallet, "UPI"),
                            paymentOption("Cards (Credit/Debit)", Icons.credit_card, "Card"),
                            paymentOption("Net Banking", Icons.account_balance, "NetBank"),
                            paymentOption("Cash on Delivery (COD)", Icons.money, "COD"),
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
                          onPressed: () {
                             showOrderSuccessDialog();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: const Row(
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
      groupValue: _paymentMethod,
      onChanged: (val) => setState(() => _paymentMethod = val!),
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

  void showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 80),
            const SizedBox(height: 20),
            const Text("Order Placed!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Payment of ₹197 via $_paymentMethod was successful.", textAlign: TextAlign.center),
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
