import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';
import '../services/google_places_service.dart';
import '../models/radiologist.dart';

class NearbyRadiologistsDialog extends StatefulWidget {
  const NearbyRadiologistsDialog({Key? key}) : super(key: key);

  @override
  State<NearbyRadiologistsDialog> createState() =>
      _NearbyRadiologistsDialogState();
}

class _NearbyRadiologistsDialogState extends State<NearbyRadiologistsDialog> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isLoadingDetails = false;
  String _errorMessage = '';
  double _searchRadius = 5.0; // Default radius in km
  Radiologist? _selectedRadiologist;

  // Service for fetching radiologists from Google Places API
  final GooglePlacesService _placesService = GooglePlacesService();
  List<Radiologist> _radiologists = [];

  // A map type variable to control normal/satellite view
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check location permission
      var status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Location permission is required to find nearby radiologists';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Update camera position
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 13.0,
        ),
      ));

      // Search for radiologists
      _searchNearbyRadiologists();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get current location: ${e.toString()}';
      });
    }
  }

  Future<void> _searchNearbyRadiologists() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _selectedRadiologist = null;
      _markers = {
        // Keep the current position marker
        Marker(
          markerId: const MarkerId('currentLocation'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your position',
          ),
        ),
      };
    });

    try {
      // Fetch radiologists from Google Places API
      final radiologists = await _placesService.searchNearbyRadiologists(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: _searchRadius,
      );

      Set<Marker> markers = {..._markers}; // Start with current position marker

      // Add markers for each radiologist
      for (var radiologist in radiologists) {
        markers.add(
          Marker(
            markerId: MarkerId(radiologist.id),
            position: radiologist.position,
            infoWindow: InfoWindow(
              title: radiologist.name,
              snippet: radiologist.rating > 0
                  ? '${radiologist.rating} ⭐ • ${radiologist.distance.toStringAsFixed(1)} km'
                  : '${radiologist.distance.toStringAsFixed(1)} km',
            ),
            onTap: () {
              _getRadiologistDetails(radiologist);
            },
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }

      setState(() {
        _markers = markers;
        _radiologists = radiologists;
        _isLoading = false;
      });

      // Show a message if no radiologists were found
      if (radiologists.isEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No radiology centers found within $_searchRadius km radius'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error searching for radiologists: ${e.toString()}';
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for radiologists: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Get detailed information for selected radiologist
  Future<void> _getRadiologistDetails(Radiologist radiologist) async {
    // Show popup immediately with basic info
    _showRadiologistPopup(radiologist, isLoading: true);

    setState(() {
      _isLoadingDetails = true;
      _selectedRadiologist = radiologist;
    });

    try {
      // Fetch detailed information for the selected radiologist
      final detailedRadiologist =
          await _placesService.getPlaceDetails(radiologist.id);

      // Make sure the distance info is preserved from the original object
      final updatedRadiologist =
          detailedRadiologist.copyWith(distance: radiologist.distance);

      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _selectedRadiologist = updatedRadiologist;
          _isLoadingDetails = false;
        });

        // Close previous dialog and reopen with full details
        Navigator.of(context).pop();
        _showRadiologistPopup(updatedRadiologist, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading details: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Display radiologist details in a popup
  void _showRadiologistPopup(Radiologist radiologist,
      {bool isLoading = false}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Container(
          width:
              MediaQuery.of(context).size.width * 0.92, // Increased from 0.85
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.88, // Increased from 0.85
          ),
          padding: const EdgeInsets.all(
              0), // Remove padding to control it better in content
          child: isLoading
              ? _buildLoadingPopup()
              : _buildRadiologistPopupContent(radiologist),
        ),
      ),
    );
  }

  // Loading indicator for popup
  Widget _buildLoadingPopup() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.turquoise),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading information...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Detailed radiologist popup content
  Widget _buildRadiologistPopupContent(Radiologist radiologist) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos carousel if available
        if (radiologist.photos.isNotEmpty) ...[
          Stack(
            children: [
              // Photo carousel with rounded top corners
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: radiologist.photos.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        radiologist.photos[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.turquoise),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 48,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Close button positioned on top right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 20, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ],

        // Content container
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radiologist.photos.isEmpty
                  ? BorderRadius.circular(24)
                  : const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            radiologist.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Status pill with rating and distance
                          _buildStatusPill(radiologist),
                        ],
                      ),
                    ),

                    // Only show close button if no photos
                    if (radiologist.photos.isEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),

                // Scrollable content area
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address
                        _buildInfoRow(
                          icon: Icons.location_on,
                          iconColor: AppTheme.turquoise,
                          text: radiologist.address,
                          fontSize: 15,
                        ),
                        const SizedBox(height: 16),

                        // Phone - only show if available
                        if (radiologist.phone.isNotEmpty) ...[
                          InkWell(
                            onTap: () => _callRadiologist(),
                            child: _buildInfoRow(
                              icon: Icons.phone,
                              iconColor: Colors.green,
                              text: radiologist.phone,
                              textColor: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Website - only show if available
                        if (radiologist.website.isNotEmpty) ...[
                          InkWell(
                            onTap: () => _visitWebsite(),
                            child: _buildInfoRow(
                              icon: Icons.language,
                              iconColor: Colors.blue,
                              text: radiologist.website,
                              textColor: Colors.blue,
                              underline: true,
                              maxLines: 1,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Hours - only show if available
                        if (radiologist.hours.isNotEmpty) ...[
                          _buildInfoRow(
                            icon: Icons.access_time,
                            iconColor: Colors.orange,
                            text: radiologist.hours.replaceAll('\\n', '\n'),
                            fontSize: 15,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Services
                        if (radiologist.services.isNotEmpty) ...[
                          Text(
                            'Available Services',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.turquoise,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildServiceChips(radiologist.services),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons at the bottom
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildActionButtons(radiologist),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Beautiful status pill showing rating and distance
  Widget _buildStatusPill(Radiologist radiologist) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.turquoise.withOpacity(0.8), AppTheme.turquoise],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.turquoise.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '${radiologist.distance.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          if (radiologist.rating > 0) ...[
            const SizedBox(width: 8),
            Container(
              height: 16,
              width: 1,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text(
              '${radiologist.rating}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Service chips with improved design
  Widget _buildServiceChips(List<String> services) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: services.map((service) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.paleBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.paleBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            service,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.turquoise.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Action buttons with consistent styling
  Widget _buildActionButtons(Radiologist radiologist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.directions),
          label: const Text('Get Directions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.turquoise,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            _launchGoogleMapsDirections();
          },
        ),
        if (radiologist.phone.isNotEmpty) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text('Call Center'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _callRadiologist();
            },
          ),
        ],
        if (radiologist.website.isNotEmpty) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.language),
            label: const Text('Visit Website'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _visitWebsite();
            },
          ),
        ],
      ],
    );
  }

  // Helper method to build info rows with consistent styling
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    Color? textColor,
    FontWeight fontWeight = FontWeight.normal,
    bool underline = false,
    int? maxLines,
    double fontSize = 16,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: fontWeight,
                decoration: underline ? TextDecoration.underline : null,
                height: 1.4,
              ),
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
            ),
          ),
        ),
      ],
    );
  }

  // Update the search radius and perform a new search
  void _updateSearchRadius(double radius) {
    setState(() {
      _searchRadius = radius;
      _selectedRadiologist = null; // Clear selection when changing radius
    });
    _searchNearbyRadiologists();
  }

  // Launch Google Maps with directions to the selected radiologist
  void _launchGoogleMapsDirections() async {
    if (_currentPosition == null || _selectedRadiologist == null) return;

    final radiologist = _selectedRadiologist!;
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&destination=${radiologist.position.latitude},${radiologist.position.longitude}'
        '&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  // Call the selected radiologist
  void _callRadiologist() async {
    if (_selectedRadiologist == null || _selectedRadiologist!.phone.isEmpty) {
      return;
    }

    final phone = _selectedRadiologist!.phone;
    final url = 'tel:$phone';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open phone dialer')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Visit the selected radiologist's website
  void _visitWebsite() async {
    if (_selectedRadiologist == null || _selectedRadiologist!.website.isEmpty)
      return;

    final website = _selectedRadiologist!.website;

    if (await canLaunchUrl(Uri.parse(website))) {
      await launchUrl(Uri.parse(website), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95, // Increased from 0.9
        height: MediaQuery.of(context).size.height * 0.85, // Increased from 0.8
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Near Radiologist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.turquoise,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(0),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search hint text
            Text(
              'Search keyword: radiology',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: const Color.fromARGB(0, 117, 117, 117),
              ),
            ),
            const SizedBox(height: 12),

            // Radius Selection and Map Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Search radius selection
                Row(
                  children: [
                    const Text(
                      'Radius: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<double>(
                      isDense: true,
                      value: _searchRadius,
                      underline: Container(
                        height: 1,
                        color: Colors.grey[400],
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          _updateSearchRadius(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 1.0,
                          child: Text('1 km'),
                        ),
                        DropdownMenuItem(
                          value: 5.0,
                          child: Text('5 km'),
                        ),
                        DropdownMenuItem(
                          value: 10.0,
                          child: Text('10 km'),
                        ),
                        DropdownMenuItem(
                          value: 25.0,
                          child: Text('25 km'),
                        ),
                        DropdownMenuItem(
                          value: 50.0,
                          child: Text('50 km'),
                        ),
                      ],
                    ),
                  ],
                ),

                // Map type toggle
                Row(
                  children: [
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _searchNearbyRadiologists,
                      tooltip: 'Refresh',
                      color: AppTheme.turquoise,
                    ),
                    const SizedBox(width: 12),

                    // Map type toggle button - modified to only use icons
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mapType = _mapType == MapType.normal
                              ? MapType.satellite
                              : MapType.normal;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _mapType == MapType.normal
                              ? Colors.white
                              : AppTheme.turquoise.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.turquoise.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _mapType == MapType.normal
                              ? Icons.map
                              : Icons.satellite,
                          size: 20,
                          color: AppTheme.turquoise,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Google Map
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.turquoise,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _getCurrentLocation,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        : GoogleMap(
                            mapType: _mapType,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 13.0,
                            ),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            markers: _markers,
                            circles: {
                              Circle(
                                circleId: const CircleId('searchRadius'),
                                center: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                radius: _searchRadius *
                                    1000, // Convert km to meters
                                fillColor: AppTheme.turquoise.withOpacity(0.1),
                                strokeColor: AppTheme.turquoise,
                                strokeWidth: 1,
                              ),
                            },
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                            },
                          ),
              ),
            ),

            // Results count
            if (!_isLoading && _errorMessage.isEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${_radiologists.length} ${_radiologists.length == 1 ? 'center' : 'centers'} found within $_searchRadius km',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
