import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  // We use Nominatim (OpenStreetMap) for completely free, keyless geocoding & autocomplete.
  // This is excellent for a demo/MVP without setting up billing.
  // Note: Nominatim requires a user-agent and asks to limit requests to 1/sec.
  
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Returns a list of address suggestions based on a query string.
  static Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&countrycodes=in');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'JaanusFarmDeliveryApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return {
            'description': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Autocomplete error: $e");
    }
    return [];
  }
}
