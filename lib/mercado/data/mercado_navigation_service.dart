import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MercadoNavigationService {
  Future<bool> openRoute({
    required LatLng coordinates,
    required String mercadoNome,
  }) {
    final encodedMercadoNome = Uri.encodeComponent(mercadoNome);
    final routeUri = Uri.parse(
      'geo:${coordinates.latitude},${coordinates.longitude}?q=${coordinates.latitude},${coordinates.longitude}($encodedMercadoNome)',
    );

    return launchUrl(routeUri, mode: LaunchMode.externalApplication);
  }
}
