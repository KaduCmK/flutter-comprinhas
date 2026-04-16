import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MercadoGeocodingService {
  Future<LatLng?> fetchCoordinates(String endereco) async {
    final normalizedAddress = endereco.trim();
    if (normalizedAddress.isEmpty) return null;

    try {
      final encodedAddress = Uri.encodeComponent(normalizedAddress);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'io.github.kaducmk.comprinhas'},
      );

      if (response.statusCode != 200) return null;

      final List data = json.decode(response.body) as List;
      if (data.isEmpty) return null;

      final lat = double.parse(data[0]['lat'] as String);
      final lon = double.parse(data[0]['lon'] as String);
      return LatLng(lat, lon);
    } catch (e) {
      debugPrint('Erro ao buscar coordenadas: $e');
      return null;
    }
  }
}
