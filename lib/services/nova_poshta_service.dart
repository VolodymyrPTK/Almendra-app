import 'dart:convert';
import 'package:http/http.dart' as http;

class NovaPoshtaService {
  static const String endpoint = 'https://api.novaposhta.ua/v2.0/json/';
  static const String _apiKey = 'd4096c654147d373e43076e0e9ef2be4';

  static Future<List<dynamic>> searchSettlements(String query) async {
    final body = {
      "apiKey": _apiKey,
      "modelName": "Address",
      "calledMethod": "getSettlements",
      "methodProperties": {"FindByString": query, "Limit": 150},
    };
    final resp = await http.post(Uri.parse(endpoint), body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (data['success'] == true) return data['data'];
    return [];
  }

  static Future<String?> resolveCityRef(String name, String area) async {
    final body = {
      "apiKey": _apiKey,
      "modelName": "Address",
      "calledMethod": "getCities",
      "methodProperties": {"FindByString": name},
    };
    final resp = await http.post(Uri.parse(endpoint), body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (data['success'] == true && data['data'] != null) {
      final list = data['data'] as List;
      final match = list.firstWhere(
        (c) => c['AreaDescription'] == area || list.length == 1,
        orElse: () => null,
      );
      return match?['Ref'];
    }
    return null;
  }

  static Future<List<dynamic>> getWarehouses(
    String cityRef, {
    String findByString = '',
    String category = 'Warehouse',
  }) async {
    final body = {
      "apiKey": _apiKey,
      "modelName": "AddressGeneral",
      "calledMethod": "getWarehouses",
      "methodProperties": {
        "CityRef": cityRef,
        "FindByString": findByString,
        "CategoryOfWarehouse": category,
      },
    };
    final resp = await http.post(Uri.parse(endpoint), body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (data['success'] == true) return data['data'];
    return [];
  }

  static Future<Map<String, dynamic>?> getTrackingStatus(String documentNumber, String phone) async {
    final body = {
      "apiKey": _apiKey,
      "modelName": "TrackingDocument",
      "calledMethod": "getStatusDocuments",
      "methodProperties": {
        "Documents": [
          {
            "DocumentNumber": documentNumber,
            "Phone": phone,
          }
        ]
      },
    };
    try {
      final resp = await http.post(Uri.parse(endpoint), body: jsonEncode(body));
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['data'] != null && (data['data'] as List).isNotEmpty) {
        return data['data'][0];
      }
    } catch (_) {}
    return null;
  }
}
