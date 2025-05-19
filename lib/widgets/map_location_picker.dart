import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationPicker extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;
  final LatLng? initialLocation;
  final bool showSearchBar;

  const MapLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
    this.showSearchBar = true,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  bool _searchBarFocused = false;
  List<String> _searchResults = [];
  bool _permissionsGranted = false;

  // Store markers
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    // Set initial location (either provided or default to Dubai)
    _selectedLocation = widget.initialLocation ?? const LatLng(25.276987, 55.296249);
    _updateMarker(); // Add initial marker
    
    // Request location permissions and get current location
    _checkPermissionsAndGetLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Check permissions and get current location
  Future<void> _checkPermissionsAndGetLocation() async {
    // Check for location permission first
    final hasPermission = await _handleLocationPermission();
    if (hasPermission) {
      setState(() {
        _permissionsGranted = true;
      });
      _getCurrentLocation();
    }
  }

  // Check and request location permissions
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        // Show dialog to enable location services
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text(
                'Location services are disabled. Please enable the services to use this feature.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if not granted
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are denied. Some features may not work.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ));
        }
        return false;
      }
    }

    // Handle permanently denied permissions
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        // Show dialog to open app settings
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permissions Denied'),
            content: const Text(
                'Location permissions are permanently denied. Please enable them in your device settings to use this feature.'),
            actions: [
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                },
              ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (!_permissionsGranted) {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;
      
      setState(() {
        _permissionsGranted = true;
      });
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Get address for the current location
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _selectedAddress = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
          _selectedAddress = _selectedAddress.replaceAll(RegExp(r'^\s*,\s*|\s*,\s*$'), ''); // Remove leading/trailing commas
        } else {
          _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
        _isLoading = false;
      });

      // Update marker
      _updateMarker();

      // Move camera to current location
      _mapController.move(_selectedLocation!, 15);

      // Notify parent
      widget.onLocationSelected(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _selectedAddress,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error getting current location: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude,
          locations.first.longitude,
        );

        setState(() {
          _searchResults = placemarks.map((place) {
            return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error searching for location: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _selectSearchResult(String address) async {
    try {
      setState(() {
        _isLoading = true;
        _searchBarFocused = false;
        _searchResults = [];
      });

      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _selectedAddress = address;
          _isLoading = false;
        });

        // Update marker
        _updateMarker();

        // Move camera to selected location
        _mapController.move(_selectedLocation!, 15);

        // Notify parent
        widget.onLocationSelected(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
          _selectedAddress,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error selecting location: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _onMapTapped(TapPosition position, LatLng location) async {
    setState(() {
      _isLoading = true;
      _selectedLocation = location;
      _searchBarFocused = false;
      _searchResults = [];
    });

    // Get address for the tapped location
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      setState(() {
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _selectedAddress = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
          _selectedAddress = _selectedAddress.replaceAll(RegExp(r'^\s*,\s*|\s*,\s*$'), ''); // Remove leading/trailing commas
        } else {
          _selectedAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        }
        _isLoading = false;
      });

      // Update marker
      _updateMarker();

      // Notify parent
      widget.onLocationSelected(
        location.latitude,
        location.longitude,
        _selectedAddress,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error getting address: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _updateMarker() {
    if (_selectedLocation != null) {
      setState(() {
        _markers = [
          Marker(
            width: 80,
            height: 80,
            point: _selectedLocation!,
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          ),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map view takes the entire space
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedLocation ?? const LatLng(25.276987, 55.296249),
            initialZoom: 15,
            onTap: _onMapTapped,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.governmentapp',
              maxZoom: 19,
            ),
            MarkerLayer(markers: _markers),
          ],
        ),

        // Search bar at the top
        if (widget.showSearchBar)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _searchLocation,
                    onTap: () {
                      setState(() {
                        _searchBarFocused = true;
                      });
                    },
                  ),
                ),
                // Search results
                if (_searchBarFocused && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_searchResults[index]),
                          onTap: () {
                            _searchController.text = _searchResults[index];
                            _selectSearchResult(_searchResults[index]);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          dense: true,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

        // Current location button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _getCurrentLocation,
            backgroundColor: Theme.of(context).primaryColor,
            mini: true,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha(26),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Selected address indicator
        if (_selectedAddress.isNotEmpty && !_searchBarFocused)
          Positioned(
            bottom: 16,
            left: 16,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _selectedAddress,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
} 