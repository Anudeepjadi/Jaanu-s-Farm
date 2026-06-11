import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _initialPosition = const LatLng(19.0760, 72.8777); // Default to Mumbai
  GoogleMapController? _controller;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _selectedPosition = _initialPosition;
      });
      _controller?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Delivery Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedPosition);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) => _controller = controller,
            onTap: (position) {
              setState(() {
                _selectedPosition = position;
              });
            },
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId("selected"),
                      position: _selectedPosition!,
                    )
                  }
                : {},
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Use Current Location"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
