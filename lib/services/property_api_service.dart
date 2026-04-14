import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/property.dart';
import '../models/property_status.dart';

/// HTTP client for the in-repo Express API (server/).
class PropertyApiService {
  PropertyApiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? propertyApiBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  /// [query] maps to q on the server (title, address, description)
  /// [status] maps to status (forSale, sold, pending)
  Future<List<Property>> fetchProperties({
    String? query,
    PropertyStatus? status,
  }) async {
    final params = <String, String>{};
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      params['q'] = trimmed;
    }
    if (status != null) {
      params['status'] = status.name;
    }
    final base = _uri('/api/properties');
    final uri = params.isEmpty ? base : base.replace(queryParameters: params);
    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw PropertyApiException(
        'Network error: ${e.toString()}',
        isRetryable: true,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyApiException(
        'Server returned ${response.statusCode}',
        statusCode: response.statusCode,
        isRetryable: response.statusCode >= 500 || response.statusCode == 429,
      );
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const PropertyApiException('Invalid response from server', isRetryable: true);
    }

    final raw = body['properties'];
    if (raw is! List) {
      throw const PropertyApiException('Unexpected data shape', isRetryable: true);
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(Property.fromJson)
        .toList(growable: false);
  }

  /// Sends fields to POST /api/properties. The server assigns id
  Future<Property> createProperty(Property draft) async {
    final uri = _uri('/api/properties');
    final payload = <String, dynamic>{
      'title': draft.title,
      'address': draft.address,
      'description': draft.description,
      'price': draft.price,
      'status': draft.status.name,
    };

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw PropertyApiException(
        'Network error: ${e.toString()}',
        isRetryable: true,
      );
    }

    if (response.statusCode == 400) {
      String message = 'Invalid data';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final details = err['details'];
        if (details is List) {
          message = details.join('\n');
        } else if (err['error'] != null) {
          message = err['error'].toString();
        }
      } catch (_) {}
      throw PropertyApiException(message, statusCode: 400, isRetryable: false);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PropertyApiException(
        'Server returned ${response.statusCode}',
        statusCode: response.statusCode,
        isRetryable: response.statusCode >= 500 || response.statusCode == 429,
      );
    }

    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return Property.fromJson(map);
    } catch (_) {
      throw const PropertyApiException('Invalid response from server', isRetryable: true);
    }
  }
}

class PropertyApiException implements Exception {
  const PropertyApiException(this.message, {this.statusCode, this.isRetryable = false});

  final String message;
  final int? statusCode;
  final bool isRetryable;

  @override
  String toString() => message;
}
