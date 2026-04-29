import 'package:geolocator/geolocator.dart' as geolocator;

class GeoLocationService {
  static Future<({double latitude, double longitude})>
  getCurrentLocation() async {
    final permission = await geolocator.Geolocator.checkPermission();

    if (permission == geolocator.LocationPermission.denied) {
      final newPermission = await geolocator.Geolocator.requestPermission();
      if (newPermission == geolocator.LocationPermission.denied ||
          newPermission == geolocator.LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    }

    final position = await geolocator.Geolocator.getCurrentPosition(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
      ),
    );

    return (latitude: position.latitude, longitude: position.longitude);
  }
}
