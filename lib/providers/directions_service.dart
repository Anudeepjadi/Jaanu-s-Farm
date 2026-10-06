import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mappls_gl/mappls_gl.dart';

class DirectionsService {
  // Using OSRM (Open Source Routing Machine) public API for free routing
  // Note: The public API has usage limits, but works perfectly for MVP/Dev without API keys.
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Fetches a route between two coordinates.
  /// Returns a map containing the polyline points (List`<LatLng>`), distance in metres, and duration in seconds.
  static Future<Map<String, dynamic>?> getRoute(double originLat, double originLng, double destLat, double destLng) async {
    try {
      // OSRM expects coordinates in lon,lat order
      final String url = '$_baseUrl/$originLng,$originLat;$destLng,$destLat?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Parse GeoJSON LineString coordinates to LatLng list
          final geometry = route['geometry'];
          List<LatLng> points = [];
          
          if (geometry['type'] == 'LineString') {
            final coordinates = geometry['coordinates'] as List;
            points = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
          }

          return {
            'points': points,
            'distance': route['distance'], // in metres
            'duration': route['duration'], // in seconds
          };
        }
      }
    } catch (e) {
      debugPrint("Directions Service Error: $e");
    }
    return null;
  }
}
