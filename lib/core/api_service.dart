import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );
  static String? token;

  static Future<Map<String, dynamic>?> restoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    final raw = prefs.getString('user');
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveSession(Map<String, dynamic> data) async {
    token = data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token!);
    await prefs.setString('user', jsonEncode(data['user']));
  }

  static Future<void> logout() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<dynamic> _request(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: _headers);
    } else if (method == 'POST') {
      response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    } else if (method == 'PATCH') {
      response = await http.patch(uri, headers: _headers, body: jsonEncode(body));
    } else {
      response = await http.delete(uri, headers: _headers);
    }
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Request failed');
    }
    return data;
  }

  static Future<void> register(Map<String, dynamic> body) async => _request('POST', '/auth/register', body: body);
  static Future<Map<String, dynamic>> verify(String email, String code) async {
    final data = await _request('POST', '/auth/verify-email', body: {'email': email, 'code': code});
    await saveSession(data);
    return Map<String, dynamic>.from(data['user']);
  }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _request('POST', '/auth/login', body: {'email': email, 'password': password});
    await saveSession(data);
    return Map<String, dynamic>.from(data['user']);
  }
  static Future<Map<String, dynamic>> me() async {
    final data = await _request('GET', '/auth/me');
    return Map<String, dynamic>.from(data['user']);
  }
  static Future<List<dynamic>> shops() async => (await _request('GET', '/shops'))['shops'];
  static Future<List<dynamic>> products(String shopId) async => (await _request('GET', '/products?shop=$shopId'))['products'];
  static Future<List<dynamic>> orders() async => (await _request('GET', '/orders/my'))['orders'];
  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _request('POST', '/orders', body: body))['order']);
  static Future<void> orderStatus(String id, String status) async =>
      _request('PATCH', '/orders/$id/status', body: {'status': status});
  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _request('POST', '/products', body: body))['product']);
  static Future<void> updateProduct(String id, Map<String, dynamic> body) async =>
      _request('PATCH', '/products/$id', body: body);
  static Future<void> deleteProduct(String id) async => _request('DELETE', '/products/$id');
  static Future<Map<String, dynamic>> createShop(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _request('POST', '/shops', body: body))['shop']);
  static Future<void> updateShop(String id, Map<String, dynamic> body) async =>
      _request('PATCH', '/shops/$id', body: body);
  static Future<void> deleteShop(String id) async => _request('DELETE', '/shops/$id');
  static Future<Map<String, dynamic>> shopAdmin(String shopId) async =>
      Map<String, dynamic>.from((await _request('GET', '/shops/$shopId/admin'))['admin']);
  static Future<void> createShopAdmin(String shopId, Map<String, dynamic> body) async =>
      _request('POST', '/shops/$shopId/admin', body: body);
  static Future<void> updateShopAdmin(String shopId, Map<String, dynamic> body) async =>
      _request('PATCH', '/shops/$shopId/admin', body: body);
  static Future<void> review(String orderId, int rating, String comment) async =>
      _request('POST', '/reviews', body: {'order': orderId, 'rating': rating, 'comment': comment});
}
