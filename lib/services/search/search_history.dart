import 'dart:convert';

import 'package:get/get.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/logger.dart';

/// Represents a search history item with name and ISIN
class SearchHistoryItem {
  final String name;
  final String? isin;
  final String? schemeCode;
  final String? iconUrl;
  final double? minimumAmount;

  SearchHistoryItem({
    required this.name,
    this.isin,
    this.schemeCode,
    this.iconUrl,
    this.minimumAmount,
  });

  /// Create from JSON map
  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      name: json['name'] ?? '',
      isin: json['isin'],
      schemeCode: json['scheme_code'],
      iconUrl: json['icon_url'],
      minimumAmount: json['minimum_amount'],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isin': isin,
      'scheme_code': schemeCode,
      'icon_url': iconUrl,
      'minimum_amount': minimumAmount,
    };
  }

  /// Check if this item has an ISIN (can navigate directly to insights)
  bool get hasIsin => isin != null && isin!.isNotEmpty;

  /// Display name for the history item
  String get displayName => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistoryItem &&
        other.name == name &&
        other.isin == isin;
  }

  @override
  int get hashCode => name.hashCode ^ (isin?.hashCode ?? 0);

  @override
  String toString() => 'SearchHistoryItem(name: $name, isin: $isin)';
}

class SearchHistoryService extends GetxService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 5;

  final RxList<SearchHistoryItem> searchHistory = <SearchHistoryItem>[].obs;

  // Initialize the service and load history from SharedPreferences
  Future<SearchHistoryService> init() async {
    try {
      await loadSearchHistory();
    } catch (e) {
      AppLogger.error(
        'Error initializing search history',
        error: e,
        tag: 'SearchHistoryService',
      );
    }
    return this;
  }

  // Load search history from StorageService
  Future<void> loadSearchHistory() async {
    try {
      final historyJson = StorageService.read(_searchHistoryKey);

      if (historyJson != null) {
        final List<dynamic> decodedList = jsonDecode(historyJson);
        searchHistory.value = decodedList.map((item) {
          // Handle both old string format and new object format for backward compatibility
          if (item is String) {
            return SearchHistoryItem(name: item);
          } else if (item is Map<String, dynamic>) {
            return SearchHistoryItem.fromJson(item);
          } else {
            return SearchHistoryItem(name: item.toString());
          }
        }).toList();
      }
    } catch (e) {
      AppLogger.error(
        'Error loading search history',
        error: e,
        tag: 'SearchHistoryService',
      );
    }
  }

  // Save search history to StorageService
  Future<void> saveSearchHistory() async {
    try {
      final historyList = searchHistory.map((item) => item.toJson()).toList();
      final historyJson = jsonEncode(historyList);
      StorageService.write(_searchHistoryKey, historyJson);
    } catch (e) {
      AppLogger.error(
        'Error saving search history',
        error: e,
        tag: 'SearchHistoryService',
      );
    }
  }

  // Add a search query to history
  Future<void> addToHistory(Map<String, dynamic> query) async {
    final name = query["name"]?.toString().trim();
    if (name?.isEmpty ?? true) return;

    final historyItem = SearchHistoryItem(
      name: name!,
      isin: query["isin"]?.toString(),
      schemeCode: query["scheme_code"]?.toString(),
      iconUrl: query["icon_url"]?.toString(),
      minimumAmount: query["minimum_amount"] != null
          ? double.tryParse(query["minimum_amount"].toString())
          : null,
    );

    // Remove if already exists to avoid duplicates
    searchHistory.remove(historyItem);

    // Add to the beginning of the list
    searchHistory.insert(0, historyItem);

    // Keep only the most recent searches
    if (searchHistory.length > _maxHistoryItems) {
      searchHistory.removeRange(_maxHistoryItems, searchHistory.length);
    }

    // Save to SharedPreferences
    await saveSearchHistory();
  }

  // Add a simple string to history (for backward compatibility)
  Future<void> addStringToHistory(String query) async {
    await addToHistory({"name": query});
  }

  // Clear search history
  Future<void> clearHistory() async {
    searchHistory.clear();
    await saveSearchHistory();
  }

  // Remove a specific item from search history
  Future<void> removeFromHistory(SearchHistoryItem item) async {
    searchHistory.remove(item);
    await saveSearchHistory();
  }

  // Remove by name (for backward compatibility)
  Future<void> removeFromHistoryByName(String name) async {
    searchHistory.removeWhere((item) => item.name == name);
    await saveSearchHistory();
  }
}
