import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapSelectionDialog extends StatefulWidget {
  final String initialAddress;
  const MapSelectionDialog({Key? key, this.initialAddress = ''})
      : super(key: key);

  @override
  _MapSelectionDialogState createState() => _MapSelectionDialogState();
}

class _MapSelectionDialogState extends State<MapSelectionDialog> {
  TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress;
    _searchController.text = widget.initialAddress;
    _getLatLngFromAddress(widget.initialAddress);
  }

  Future<void> _getLatLngFromAddress(String address) async {
    if (address.trim().isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 14),
        );
      }
    } catch (_) {}
  }

  Future<void> _updateAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _selectedAddress =
              '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
          _searchController.text = _selectedAddress;
        });
      }
    } catch (_) {}
  }

  Future<void> _locateUser() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController
        ?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 16));
    await _updateAddressFromLatLng(_selectedLocation!);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Stack(
        children: [
          SizedBox(
            height: 500,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search address',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _getLatLngFromAddress(value),
                  ),
                ),
                // Map
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target:
                          _selectedLocation ?? const LatLng(37.7749, -122.4194),
                      zoom: 12,
                    ),
                    mapType: MapType.satellite,
                    onTap: (latLng) async {
                      setState(() => _selectedLocation = latLng);
                      await _updateAddressFromLatLng(latLng);
                    },
                    markers: _selectedLocation == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('picked_location'),
                              position: _selectedLocation!,
                            ),
                          },
                  ),
                ),
                // Confirm Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedAddress);
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 70,
            left: 10,
            child: FloatingActionButton(
              onPressed: _locateUser,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
