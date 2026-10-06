import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Subscription handle so callers can cancel streaming
  static StreamSubscription<Position>? _positionStreamSubscription;

  static Future<bool> _handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  /// Returns the current one-shot device position, or null on failure/denial.
  static Future<Position?> getCurrentPosition() async {
    try {
      if (!await _handlePermission()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      if (kDebugMode) print("Location Error: $e");
      return null;
    }
  }

  /// Emits a new [Position] whenever the device moves more than 5 metres.
  /// Uses [bestForNavigation] accuracy for live delivery tracking.
  static Stream<Position> getLiveLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    );
  }

  /// Starts live GPS tracking and calls [onPosition] with each new position.
  /// Cancels any previously running tracking stream first.
  static Future<bool> startTracking(void Function(Position) onPosition) async {
    if (!await _handlePermission()) return false;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        getLiveLocationStream().listen(onPosition, onError: (e) {
      if (kDebugMode) print("Tracking stream error: $e");
    });
    return true;
  }

  /// Cancels the active GPS tracking stream.
  static Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Returns the straight-line distance in **metres** between two coordinates.
  static double distanceBetween(
    double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Converts coordinates to a human-readable address string.
  static Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        return "${p.street}, ${p.subLocality}, ${p.locality}";
      }
    } catch (e) {
      if (kDebugMode) print("Geocoding Error: $e");
    }
    return "${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}";
  }
}

