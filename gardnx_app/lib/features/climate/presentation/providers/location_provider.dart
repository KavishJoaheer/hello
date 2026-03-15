import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gardnx_app/features/climate/domain/models/location_info.dart';

final currentLocationProvider =
    FutureProvider<LocationInfo>((ref) async {
  return _getLocation();
});

Future<LocationInfo> _getLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return LocationInfo.defaultNorth();
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return LocationInfo.defaultNorth();
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return LocationInfo.defaultNorth();
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );
    return LocationInfo.fromLatLon(position.latitude, position.longitude);
  } catch (_) {
    return LocationInfo.defaultNorth();
  }
}
