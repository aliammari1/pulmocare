import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/radiologist.dart';
import '../config/api_keys.dart'; // You'll need to create this file with your API key

class GooglePlacesService {
  // Base URL for Google Places API
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Method to search for nearby radiologists using Google Places API
  Future<List<Radiologist>> searchNearbyRadiologists({
    required double latitude,
    required double longitude,
    required double radius, // in km
  }) async {
    final String url = '$_baseUrl/nearbysearch/json?'
        'location=$latitude,$longitude'
        '&radius=${(radius * 1000).toInt()}' // Convert km to meters
        '&type=health'
        '&keyword=radiologue'
        '&language=fr'
        '&key=${ApiKeys.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          final List<Radiologist> radiologists = [];

          for (var placeData in results) {
            final lat = placeData['geometry']['location']['lat'];
            final lng = placeData['geometry']['location']['lng'];
            final position = LatLng(lat, lng);

            // Calculate distance using Haversine formula
            final distance = _calculateDistance(latitude, longitude, lat, lng);

            // Extract available fields and use defaults if not available
            radiologists.add(Radiologist(
              id: placeData['place_id'],
              name: placeData['name'],
              address: placeData['vicinity'] ?? '',
              rating: placeData['rating']?.toDouble() ?? 0.0,
              phone: '', // Will be filled by getPlaceDetails
              website: '', // Will be filled by getPlaceDetails
              hours: '', // Will be filled by getPlaceDetails
              position: position,
              services: [
                'Radiologie'
              ], // Default, will be enhanced by getPlaceDetails
              photos: placeData['photos'] != null
                  ? [_getPhotoUrl(placeData['photos'][0]['photo_reference'])]
                  : [],
              distance: distance,
            ));
          }

          return radiologists;
        } else {
          throw Exception('Places API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to load radiologists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching for radiologists: $e');
    }
  }

  // Method to get detailed information for a selected radiologist
  Future<Radiologist> getPlaceDetails(String placeId) async {
    final String url = '$_baseUrl/details/json?'
        'place_id=$placeId'
        '&fields=name,formatted_address,formatted_phone_number,website,opening_hours,photos,rating,types,geometry'
        '&language=en'
        '&key=${ApiKeys.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];

          // Extract services based on types and known radiologist services
          List<String> services =
              _extractRadiologyServices(result['types'] ?? []);

          // Extract opening hours if available
          String hours = '';
          if (result['opening_hours'] != null &&
              result['opening_hours']['weekday_text'] != null) {
            hours = result['opening_hours']['weekday_text'].join('\\n');
          }

          // Extract photos if available
          List<String> photos = [];
          if (result['photos'] != null) {
            for (var photo in result['photos']) {
              photos.add(_getPhotoUrl(photo['photo_reference']));
              if (photos.length >= 3) break; // Limit to 3 photos
            }
          }

          // Get position (with null safety)
          LatLng position;
          if (result['geometry'] != null &&
              result['geometry']['location'] != null &&
              result['geometry']['location']['lat'] != null &&
              result['geometry']['location']['lng'] != null) {
            position = LatLng(
              result['geometry']['location']['lat'],
              result['geometry']['location']['lng'],
            );
          } else {
            // If geometry data is missing, use a fallback (this shouldn't happen with proper API key)
            position = const LatLng(0, 0);
          }

          // Create enhanced radiologist with detailed information
          return Radiologist(
            id: placeId,
            name: result['name'] ?? 'Unknown Name',
            address: result['formatted_address'] ??
                result['vicinity'] ??
                'No address available',
            rating: result['rating']?.toDouble() ?? 0.0,
            phone: result['formatted_phone_number'] ?? '',
            website: result['website'] ?? '',
            hours: hours,
            position: position,
            services: services,
            photos: photos,
            distance: 0, // This will be filled by the caller
          );
        } else {
          throw Exception('Places API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to get place details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting place details: $e');
    }
  }

  // Helper method to generate photo URL
  String _getPhotoUrl(String photoReference) {
    return '$_baseUrl/photo?maxwidth=800&photoreference=$photoReference&key=${ApiKeys.googleMapsApiKey}';
  }

  // Helper method to extract radiological services from place types
  List<String> _extractRadiologyServices(List<dynamic> types) {
    List<String> services = ['Radiologie'];

    // Map common Google Place types to radiological services
    final Map<String, String> typeToService = {
      'doctor': 'Consultation médicale',
      'health': 'Services de santé',
      'hospital': 'Hôpital',
      'physiotherapist': 'Physiothérapie',
      'medical_office': 'Cabinet médical',
    };

    // Add services based on place types
    for (var type in types) {
      if (typeToService.containsKey(type)) {
        services.add(typeToService[type]!);
      }
    }

    // Add common radiological services
    final radiologyServices = [
      'Radiographie',
      'Échographie',
      'IRM',
      'Scanner',
    ];

    // Add at least 2 random radiological services if we have few services
    if (services.length < 3) {
      radiologyServices.shuffle();
      for (var i = 0; i < 2 && i < radiologyServices.length; i++) {
        services.add(radiologyServices[i]);
      }
    }

    return services.toSet().toList(); // Remove duplicates
  }

  // Calculate distance between two coordinates in km using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in km
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
