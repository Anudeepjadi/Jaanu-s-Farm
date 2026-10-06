import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'location_service.dart';
import 'providers/places_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _initialPosition = const LatLng(19.0760, 72.8777);
  MapplsMapController? _controller;
  LatLng? _selectedPosition;
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (query.trim().isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      setState(() => _isSearching = true);
      final results = await PlacesService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onSuggestionSelected(Map<String, dynamic> suggestion) {
    FocusScope.of(context).unfocus();
    final newPos = LatLng(suggestion['lat'], suggestion['lon']);
    setState(() {
      _selectedPosition = newPos;
      _searchResults = [];
      _searchController.text = suggestion['description'].split(',').first;
    });
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
    _updateMarker();
  }

  void _getCurrentLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _initialPosition = newPos;
        _selectedPosition = _initialPosition;
      });
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
      _updateMarker();
    }
  }

  void _updateMarker() async {
    if (_controller == null || _selectedPosition == null) return;
    await _controller!.clearSymbols();
    await _controller!.addSymbol(
      SymbolOptions(
        geometry: _selectedPosition!,
        iconImage: "marker_icon",
        iconSize: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapplsMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _controller = controller;
              if (_selectedPosition != null) {
                _updateMarker();
              }
            },
            onMapClick: (point, latlng) {
              FocusScope.of(context).unfocus();
              setState(() {
                _selectedPosition = latlng;
                _searchResults = [];
              });
              _updateMarker();
            },
          ),
          
          // Custom Top App Bar with Search
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Colors.black87),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Set Delivery Location",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search for area, street name...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _isSearching 
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _searchController.text.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Autocomplete Results Overlay
          if (_searchResults.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = _searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                      title: Text(
                        suggestion['description'].split(',').first,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        suggestion['description'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      onTap: () => _onSuggestionSelected(suggestion),
                    );
                  },
                ),
              ),
            ),

          // Bottom Actions
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedPosition != null) {
                        Navigator.pop(context, _selectedPosition);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a location on the map")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text("Confirm Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
