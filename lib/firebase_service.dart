import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://jaanu-s-farm-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up user and save to database
  Future<String?> signUp(String email, String password, String name, String phone) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _dbRef.child('users').child(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': ServerValue.timestamp,
        });
        return null; // Success
      }
      return "User creation failed";
    } catch (e) {
      return e.toString();
    }
  }

  // Fetch user profile details from Realtime Database
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _dbRef.child('users').child(uid).get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
    return null;
  }

  // Save Order to Firebase
  Future<String?> saveOrder(
    List<Map<String, dynamic>> cartItems, 
    double total, 
    String address, {
    double? lat,
    double? lng,
  }) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      final String? orderId = _dbRef.child('orders').push().key;
      if (orderId == null) return null;

      await _dbRef.child('orders').child(orderId).set({
        'userId': userId,
        'items': cartItems,
        'total': total,
        'address': address,
        'latitude': lat,
        'longitude': lng,
        'status': 'Placed',
        'timestamp': ServerValue.timestamp,
      });
      return orderId;
    } catch (e) {
      debugPrint("Error saving order: $e");
      return null;
    }
  }

  // Fetch Products from Firebase (Real-time)
  Stream<List<Map<String, String>>> getProducts() {
    return _dbRef.child('products').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return [];
      
      final Map<dynamic, dynamic> productsMap = data;
      
      return productsMap.entries.map((e) {
        final value = e.value as Map;
        return {
          'title': value['title']?.toString() ?? '',
          'price': value['price']?.toString() ?? '',
          'image': value['image']?.toString() ?? '',
          'desc': value['desc']?.toString() ?? '',
        };
      }).toList();
    });
  }

  // Fetch Orders from Firebase (Real-time)
  Stream<List<Map<String, dynamic>>> getOrders() {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _dbRef
        .child('orders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <Map<String, dynamic>>[];

      final Map<dynamic, dynamic> ordersMap = data;

      return ordersMap.entries.map((e) {
        final value = Map<String, dynamic>.from(e.value as Map);
        value['id'] = e.key;
        return value;
      }).toList();
    });
  }

  // Upload initial products if empty
  Future<void> uploadInitialProducts(List<Map<String, String>> products) async {
    try {
      final snapshot = await _dbRef.child('products').get();
      if (!snapshot.exists) {
        for (var product in products) {
          await _dbRef.child('products').push().set(product);
        }
      }
    } catch (e) {
      debugPrint("Error uploading initial products: $e");
    }
  }

  // ─── GPS Tracking ────────────────────────────────────────────────────────

  /// Writes the delivery partner's current GPS position to Firebase under
  /// `deliveries/{orderId}/partnerLocation`.
  /// Call this every time the partner's device position updates.
  Future<void> updateDeliveryPartnerLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dbRef.child('deliveries').child(orderId).update({
        'partnerLocation': {
          'lat': latitude,
          'lng': longitude,
          'updatedAt': ServerValue.timestamp,
        },
        'partnerId': _auth.currentUser?.uid,
      });
    } catch (e) {
      debugPrint("Error updating partner location: $e");
    }
  }

  /// Clears the partner location from Firebase when delivery ends or app closes.
  Future<void> clearDeliveryPartnerLocation(String orderId) async {
    try {
      await _dbRef.child('deliveries').child(orderId).child('partnerLocation').remove();
    } catch (e) {
      debugPrint("Error clearing partner location: $e");
    }
  }

  /// Returns a real-time stream of the delivery partner's GPS coordinates
  /// for the given [orderId]. Emits `null` when no location is available.
  Stream<Map<String, double>?> streamDeliveryPartnerLocation(String orderId) {
    return _dbRef
        .child('deliveries')
        .child(orderId)
        .child('partnerLocation')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      final map = Map<String, dynamic>.from(data);
      final lat = (map['lat'] as num?)?.toDouble();
      final lng = (map['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    });
  }

  /// Returns a real-time stream of a single order given its [orderId].
  Stream<Map<String, dynamic>?> streamOrder(String orderId) {
    return _dbRef.child('orders').child(orderId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      final map = Map<String, dynamic>.from(data);
      map['id'] = orderId;
      return map;
    });
  }

  /// Updates the status field of an order (e.g. 'Picked Up', 'On the Way', 'Delivered').
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _dbRef.child('orders').child(orderId).update({'status': status});
    } catch (e) {
      debugPrint("Error updating order status: $e");
    }
  }

  /// Streams all orders regardless of user (for admin use).
  Stream<List<Map<String, dynamic>>> getAllOrders() {
    return _dbRef.child('orders').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <Map<String, dynamic>>[];
      return data.entries.map((e) {
        final value = Map<String, dynamic>.from(e.value as Map);
        value['id'] = e.key;
        return value;
      }).toList()
        ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    });
  }

}
