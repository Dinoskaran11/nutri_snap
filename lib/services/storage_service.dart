import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends ChangeNotifier {
  static const String _historyKey = 'scanned_history';
  static const String _favoritesKey = 'favorites';
  static const String _dailyTipKey = 'daily_tip';

  // Save a scan result to history
  Future<void> saveScan(Map<String, dynamic> scanData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];

    // Add timestamp if not present
    if (!scanData.containsKey('timestamp')) {
      scanData['timestamp'] = DateTime.now().toIso8601String();
    }

    // Encode to JSON string
    String jsonString = jsonEncode(scanData);

    // Insert at beginning of list (newest first)
    history.insert(0, jsonString);

    // Limit history size (e.g., 50 items)
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    await prefs.setStringList(_historyKey, history);
    notifyListeners();
  }

  // Get full scan history
  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];

    return history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Map<String, dynamic> productData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    // We identify favorites by productName unique for now, or generate an ID.
    // Ideally scanData has a unique ID, but we'll use productName + timestamp or just productName if generic.
    // Let's use productName as the key for simplicity in this prototype.
    String productName = productData['productName'] ?? 'Unknown Product';

    // Check if already exists
    int existingIndex = -1;
    for (int i = 0; i < favorites.length; i++) {
      Map<String, dynamic> item = jsonDecode(favorites[i]);
      if (item['productName'] == productName) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      // Remove from favorites
      favorites.removeAt(existingIndex);
      await prefs.setStringList(_favoritesKey, favorites);
      notifyListeners();
      return false; // Not favorite anymore
    } else {
      // Add to favorites
      // Ensure raw data is saved
      if (!productData.containsKey('timestamp')) {
        productData['timestamp'] = DateTime.now().toIso8601String();
      }
      favorites.insert(0, jsonEncode(productData));
      await prefs.setStringList(_favoritesKey, favorites);
      notifyListeners();
      return true; // Is now favorite
    }
  }

  // Check if a product is favorited
  Future<bool> isFavorite(String productName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    for (String itemStr in favorites) {
      Map<String, dynamic> item = jsonDecode(itemStr);
      if (item['productName'] == productName) {
        return true;
      }
    }
    return false;
  }

  // Get all favorites
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    return favorites.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>?> getCachedDailyTip(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final rawTip = prefs.getString(_dailyTipKey);
    if (rawTip == null) return null;

    try {
      final tip = jsonDecode(rawTip) as Map<String, dynamic>;
      return tip['dateKey'] == dateKey ? tip : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCachedDailyTip(Map<String, dynamic> tip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyTipKey, jsonEncode(tip));
  }

  // Clear all data (for debug)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
