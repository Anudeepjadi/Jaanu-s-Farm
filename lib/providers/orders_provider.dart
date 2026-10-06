import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final ordersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getOrders();
});
