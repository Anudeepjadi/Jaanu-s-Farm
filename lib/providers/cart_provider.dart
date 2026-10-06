import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateNotifier to manage the Cart
class CartNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  CartNotifier() : super([]);

  void addToCart(String title, String price, String imagePath) {
    int index = state.indexWhere((item) => item['title'] == title);
    if (index != -1) {
      // Increment quantity if it exists
      final newState = [...state];
      newState[index] = {
        ...newState[index],
        'quantity': (newState[index]['quantity'] ?? 1) + 1,
      };
      state = newState;
    } else {
      // Add new item
      state = [
        ...state,
        {
          "title": title,
          "price": price,
          "image": imagePath,
          "quantity": 1,
        }
      ];
    }
  }

  void updateQuantity(int index, int delta) {
    final newState = [...state];
    int newQty = (newState[index]['quantity'] ?? 1) + delta;
    if (newQty > 0) {
      newState[index] = {
        ...newState[index],
        'quantity': newQty,
      };
      state = newState;
    } else {
      // Remove item if quantity goes to 0
      newState.removeAt(index);
      state = newState;
    }
  }

  void removeFromCart(int index) {
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  void clearCart() {
    state = [];
  }

  double get itemTotal {
    return state.fold<double>(0.0, (sum, item) {
      String priceStr = item['price']!.toString().replaceAll('₹', '').trim();
      double price = double.tryParse(priceStr) ?? 0;
      int qty = item['quantity'] ?? 1;
      return sum + (price * qty);
    });
  }

  double get grandTotal {
    double total = itemTotal;
    return total > 0 ? total + 15 + 2 : 0.0; // itemTotal + delivery + handling
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<Map<String, dynamic>>>((ref) {
  return CartNotifier();
});
