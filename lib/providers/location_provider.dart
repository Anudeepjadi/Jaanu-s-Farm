import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../location_service.dart';

class LocationState {
  final LatLng? coordinates;
  final String address;
  final bool isLoading;

  LocationState({
    this.coordinates,
    this.address = "Detecting location...",
    this.isLoading = true,
  });

  LocationState copyWith({
    LatLng? coordinates,
    String? address,
    bool? isLoading,
  }) {
    return LocationState(
      coordinates: coordinates ?? this.coordinates,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      final address = await LocationService.getAddressFromLatLng(position.latitude, position.longitude);
      state = state.copyWith(
        coordinates: LatLng(position.latitude, position.longitude),
        address: address,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        address: "Location unavailable. Please select manually.",
        isLoading: false,
      );
    }
  }

  Future<void> updateLocation(LatLng newCoordinates) async {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(
      coordinates: newCoordinates,
      address: "Fetching address...",
    );
    try {
      final address = await LocationService.getAddressFromLatLng(
        newCoordinates.latitude, newCoordinates.longitude
      );
      state = state.copyWith(address: address, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        address: "${newCoordinates.latitude.toStringAsFixed(4)}, ${newCoordinates.longitude.toStringAsFixed(4)}",
        isLoading: false,
      );
    }
  }

  Future<void> refreshCurrentLocation() async {
    state = state.copyWith(isLoading: true);
    await _initLocation();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
