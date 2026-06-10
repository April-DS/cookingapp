import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Sends the current shopping list to the Grocery Companion server
/// (Pantry Pal — https://github.com/April-DS/pantry_pal), which answers
/// what to buy where this week based on Woolworths/Coles price history.
class CompanionService {
  static const _urlKey = 'companion_server_url';
  static const defaultUrl = 'http://192.168.1.106:8000';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey) ?? defaultUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url.trim());
  }

  /// POSTs unchecked items as `{items: [{name, qty}], sent_at}` to
  /// `<server>/api/lists`. Returns a short summary; throws on failure.
  static Future<String> sendShoppingList(
    Map<String, String> ingredients,
    Map<String, bool> checked,
  ) async {
    final items = ingredients.entries
        .where((e) => !(checked[e.key] ?? false))
        .map((e) => {
              'name': e.key,
              if (e.value.isNotEmpty) 'qty': e.value,
            })
        .toList();
    if (items.isEmpty) {
      return 'Nothing to send — everything is checked off.';
    }
    final url = await getServerUrl();
    final body = jsonEncode({
      'items': items,
      'sent_at': DateTime.now().toIso8601String(),
    });

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(Uri.parse('$url/api/lists'));
      request.headers.contentType = ContentType.json;
      request.write(body);
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('Server said ${response.statusCode}: $text');
      }
      final data = jsonDecode(text) as Map<String, dynamic>;
      final matched = data['matched'] ?? 0;
      final unmatched = (data['unmatched'] as List?)?.length ?? 0;
      return 'Sent ${items.length} items — $matched price-tracked'
          '${unmatched > 0 ? ', $unmatched not tracked yet' : ''}.';
    } finally {
      client.close();
    }
  }
}
