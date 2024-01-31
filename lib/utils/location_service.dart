import 'dart:convert';

import 'package:find_location/entitites/location.dart';
import 'package:find_location/entitites/place.dart';
import 'package:find_location/entitites/suggetion.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';

class LocationService {
  final client = Client();

  static const String androidKey = 'AIzaSyBPqDQHg0Tr6TNGt7lS8evYEcq2Ax8fQ68';

  Future<Position> currentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Future<List<Suggestion>> fetchSuggestions(String input) async {
    final sessionToken = const Uuid().v4();

    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=address&language=ID&components=country:id&key=$androidKey&sessiontoken=$sessionToken';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // compose suggestions in a list
        return result['predictions']
            .map<Suggestion>((p) => Suggestion(p['place_id'], p['description']))
            .toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<Place> getPlaceDetailFromId(String placeId) async {
    final sessionToken = const Uuid().v4();

    final request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=address_component&key=$androidKey&sessiontoken=$sessionToken';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final components =
            result['result']['address_components'] as List<dynamic>;
        // build result
        final place = Place();
        for (var c in components) {
          final List type = c['types'];

          if (type.contains('street_number')) {
            place.streetNumber = c['long_name'];
          }

          if (type.contains('route')) {
            place.street = c['long_name'];
          }

          if (type.contains('locality')) {
            place.city = c['long_name'];
          }

          if (type.contains('postal_code')) {
            place.zipCode = c['long_name'];
          }
        }
        return place;
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<Location?> getGeoLocationFromId(String placeId) async {
    final sessionToken = const Uuid().v4();

    final request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$androidKey&sessiontoken=$sessionToken';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final location = result['result']['geometry']['location'];

        return Location.fromMap(location);
      }

      // throw Exception(result['error_message']);
    } else {
      // throw Exception('Failed to fetch suggestion');
    }
    return null;
  }
}
