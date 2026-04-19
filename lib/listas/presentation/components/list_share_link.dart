import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ListShareLink {
  static const _defaultBaseUrl = 'https://comprinhas-460819.web.app';

  static String build(String listId) {
    final encodedListId = base64Url.encode(utf8.encode(listId));
    return buildFromEncodedId(encodedListId);
  }

  static String buildFromEncodedId(String encodedListId) {
    final baseUrl = _resolveBaseUrl();
    return '$baseUrl/join/$encodedListId';
  }

  static String? extractEncodedId(String rawValue) {
    final trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) return null;

    final uri = Uri.tryParse(trimmedValue);
    if (uri == null) return null;

    if (uri.scheme == 'comprinhas' &&
        uri.host == 'join' &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }

    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[segments.length - 2] == 'join') {
      return segments.last;
    }

    return null;
  }

  static String _resolveBaseUrl() {
    final configuredBaseUrl = dotenv.env['APP_WEB_BASE_URL'];
    if (configuredBaseUrl != null && configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl.replaceAll(RegExp(r'/$'), '');
    }

    if (kIsWeb) {
      return Uri.base.origin;
    }

    return _defaultBaseUrl;
  }
}
