import 'dart:async';
import 'dart:js' as js;

class GeoLocationService {
  static Future<({double latitude, double longitude})>
  getCurrentLocation() async {
    final completer = Completer<({double latitude, double longitude})>();

    try {
      final navigator = js.context['navigator'];
      final geolocation = navigator['geolocation'];

      if (geolocation == null) {
        completer.completeError(
          Exception('Geolocation tidak didukung browser ini'),
        );
        return completer.future;
      }

      geolocation.callMethod('getCurrentPosition', [
        js.JsFunction.withThis((thisArg, position) {
          try {
            final coords = position['coords'];
            final lat = (coords['latitude'] as num).toDouble();
            final lng = (coords['longitude'] as num).toDouble();
            completer.complete((latitude: lat, longitude: lng));
          } catch (e) {
            completer.completeError(Exception('Error parsing coordinates: $e'));
          }
        }),
        js.JsFunction.withThis((thisArg, error) {
          try {
            final code = error['code'];
            final message = error['message'] ?? 'Unknown error';
            completer.completeError(
              Exception('Geolocation error ($code): $message'),
            );
          } catch (e) {
            completer.completeError(Exception('Geolocation error: $error'));
          }
        }),
      ]);
    } catch (e) {
      completer.completeError(Exception('Error getting location: $e'));
    }

    return completer.future;
  }
}
