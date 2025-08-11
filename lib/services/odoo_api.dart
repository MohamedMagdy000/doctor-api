import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class OdooApi {
  // ضيفنا الـ baseUrl لاستخدامه مع الصور اللي بترجع Path فقط
  static const String baseUrl   = 'https://codesolutioneg-odoo-api.odoo.com';
  static const String kCatsUrl  = '$baseUrl/odoo/public/categories';
  static const String kProdsUrl = '$baseUrl/odoo/public/products';

  static Future<List<CatParent>> fetchCategories() async {
    final r = await http.get(Uri.parse(kCatsUrl));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final List data = json.decode(utf8.decode(r.bodyBytes));
    return data
        .cast<Map>()
        .map((e) => CatParent.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<List<ProductItem>> fetchProducts() async {
    final r = await http.get(Uri.parse(kProdsUrl));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final List data = json.decode(utf8.decode(r.bodyBytes));
    return data
        .cast<Map>()
        .map((e) => ProductItem.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
