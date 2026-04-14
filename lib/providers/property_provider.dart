import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/property.dart';
import '../models/property_status.dart';
import '../services/property_api_service.dart';

typedef AddPropertyResult = ({String? error, String? info});

class PropertyProvider extends ChangeNotifier {
  PropertyProvider({PropertyApiService? apiService})
      : _api = apiService ?? PropertyApiService();

  final PropertyApiService _api;

  List<Property> _remote = [];
  String _query = '';
  PropertyStatus? _statusFilter;
  bool _loading = false;
  String? _errorMessage;
  bool _errorRetryable = false;
  int _fetchSeq = 0;
  Timer? _searchDebounce;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  bool get errorRetryable => _errorRetryable;

  String get searchQuery => _query;
  PropertyStatus? get statusFilter => _statusFilter;

  /// Results for the current server-side search and status filter
  List<Property> get allProperties => _remote;

  List<Property> get visibleProperties => _remote;

  /// initialize() / refreshFromApi(): load data from the API with current filters
  Future<void> initialize() async {
    await _fetchWithCurrentFilters();
  }

  /// setSearchQuery: waits 350 ms after you stop typing (debounce), then fetches again so the server does the search
  void setSearchQuery(String value) {
    _query = value;
    notifyListeners();
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      _searchDebounce = null;
      unawaited(_fetchWithCurrentFilters());
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchDebounce = null;
      unawaited(_fetchWithCurrentFilters());
    });
  }

  /// setStatusFilter: changes "All / For sale / Sold / Pending" and refetches
  void setStatusFilter(PropertyStatus? status) {
    _statusFilter = status;
    _searchDebounce?.cancel();
    _searchDebounce = null;
    notifyListeners();
    unawaited(_fetchWithCurrentFilters());
  }

  Future<void> refreshFromApi() async {
    await _fetchWithCurrentFilters();
  }

  Future<void> _fetchWithCurrentFilters() async {
    final id = ++_fetchSeq;
    _loading = true;
    _errorMessage = null;
    _errorRetryable = false;
    notifyListeners();

    try {
      final list = await _api.fetchProperties(
        query: _query.trim().isNotEmpty ? _query.trim() : null,
        status: _statusFilter,
      );
      if (id != _fetchSeq) return;
      _remote = list;
      _errorMessage = null;
    } on PropertyApiException catch (e) {
      if (id != _fetchSeq) return;
      _errorMessage = e.message;
      _errorRetryable = e.isRetryable;
    } catch (e) {
      if (id != _fetchSeq) return;
      _errorMessage = 'Something went wrong: $e';
      _errorRetryable = true;
    } finally {
      if (id == _fetchSeq) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryAfterError() async {
    if (_errorMessage == null) return;
    await _fetchWithCurrentFilters();
  }

  /// Persists via 'POST /api/properties' only; refreshes the list on success
  /// addUserProperty: calls createProperty, then refetches the list so the home screen stays in sync
  Future<AddPropertyResult> addUserProperty(Property property) async {
    try {
      await _api.createProperty(property);
      await _fetchWithCurrentFilters();
      return (error: null, info: null);
    } on PropertyApiException catch (e) {
      return (error: e.message, info: null);
    } catch (e) {
      return (error: e.toString(), info: null);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
