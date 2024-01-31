import 'dart:async';

import 'package:find_location/entitites/suggetion.dart';
import 'package:find_location/utils/location_service.dart';
import 'package:find_location/widgets/address_search.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();

    _searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder(
              future: LocationService().currentPosition(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasData) {
                  final data = snapshot.data!;

                  return GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(data.latitude, data.longitude),
                      zoom: 14.4746,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                    },
                  );
                }

                return const SizedBox();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                readOnly: true,
                controller: _searchController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: "Find location....",
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIcon: const Icon(Icons.search),
                  prefixIconColor: Colors.grey,
                ),
                onTap: () async {
                  final Suggestion? result = await showSearch(
                    context: context,
                    delegate: AddressSearch(),
                  );

                  _searchController.text = result?.description ?? '';

                  // This will change the text displayed in the TextField
                  if (result != null) {
                    final geoLoc = await LocationService()
                        .getGeoLocationFromId(result.placeId);

                    if (geoLoc != null) {
                      _goToGeoLocation(
                          lat: geoLoc.lat?.toDouble() ?? 0,
                          lng: geoLoc.lng?.toDouble() ?? 0);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCurrentLocation,
        label: const Text('My Location'),
        icon: const Icon(Icons.location_searching),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final currentPosition = await LocationService().currentPosition();

    CameraPosition kLake = CameraPosition(
      // bearing: 192.8334901395799,
      target: LatLng(currentPosition.latitude, currentPosition.longitude),
      zoom: 14.4746,
    );

    final GoogleMapController controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(kLake));
  }

  Future<void> _goToGeoLocation(
      {required double lat, required double lng}) async {
    CameraPosition camera = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 14.4746,
    );

    final GoogleMapController controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(camera));
  }
}
