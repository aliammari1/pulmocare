import 'package:google_maps_flutter/google_maps_flutter.dart';

class Radiologist {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String phone;
  final String website;
  final String hours;
  final LatLng position;
  final List<String> services;
  final List<String> photos;
  final double distance;

  Radiologist({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.phone,
    required this.website,
    required this.hours,
    required this.position,
    required this.services,
    required this.photos,
    required this.distance,
  });

  // Create a new Radiologist with some properties updated
  Radiologist copyWith({
    String? id,
    String? name,
    String? address,
    double? rating,
    String? phone,
    String? website,
    String? hours,
    LatLng? position,
    List<String>? services,
    List<String>? photos,
    double? distance,
  }) {
    return Radiologist(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      hours: hours ?? this.hours,
      position: position ?? this.position,
      services: services ?? this.services,
      photos: photos ?? this.photos,
      distance: distance ?? this.distance,
    );
  }

  factory Radiologist.fromJson(Map<String, dynamic> json) {
    return Radiologist(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      rating: json['rating']?.toDouble() ?? 0.0,
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      hours: json['hours'] ?? '',
      position: LatLng(
        json['position']['lat']?.toDouble() ?? 0.0,
        json['position']['lng']?.toDouble() ?? 0.0,
      ),
      services: List<String>.from(json['services'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      distance: json['distance']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'phone': phone,
      'website': website,
      'hours': hours,
      'position': {
        'lat': position.latitude,
        'lng': position.longitude,
      },
      'services': services,
      'photos': photos,
      'distance': distance,
    };
  }
}
