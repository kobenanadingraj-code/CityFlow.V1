import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client HTTP central : base URL, JWT (access + refresh), et helpers
/// get/post/patch/delete qui retentent automatiquement une fois après un
/// refresh de token sur 401.
///
/// Base URL : passe --dart-define=API_BASE_URL=https://ton-domaine.onrender.com
/// au build/run. En dev local (émulateur Android), 10.0.2.2 pointe vers le
/// localhost de la machine hôte — adapte selon ta config.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, [this.body]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  final _storage = const FlutterSecureStorage();
  static const _kAccessKey = 'cf_access_token';
  static const _kRefreshKey = 'cf_refresh_token';

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _kAccessKey, value: access);
    await _storage.write(key: _kRefreshKey, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccessKey);
  Future<String?> get _refreshToken => _storage.read(key: _kRefreshKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessKey);
    await _storage.delete(key: _kRefreshKey);
  }

  Future<bool> get isLoggedIn async => (await accessToken) != null;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$cleanPath').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString())),
    );
  }

  Future<Map<String, String>> _headers({bool auth = true, bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = await accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _refreshToken;
    if (refresh == null) return false;
    final resp = await http.post(
      _uri('/api/auth/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (resp.statusCode != 200) return false;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    await _storage.write(key: _kAccessKey, value: data['access'] as String);
    return true;
  }

  Future<dynamic> _decode(http.Response resp) {
    if (resp.body.isEmpty) return Future.value(null);
    try {
      return Future.value(jsonDecode(utf8.decode(resp.bodyBytes)));
    } catch (_) {
      return Future.value(resp.body);
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(auth: auth);
    http.Response resp;

    Future<http.Response> send() {
      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers);
        case 'POST':
          return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PATCH':
          return http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PUT':
          return http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'DELETE':
          return http.delete(uri, headers: headers);
        default:
          throw ArgumentError('Méthode inconnue : $method');
      }
    }

    resp = await send();

    if (resp.statusCode == 401 && auth && retry) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _request(method, path, query: query, body: body, auth: auth, retry: false);
      }
      await clearTokens();
      throw ApiException(401, 'Session expirée, reconnecte-toi.');
    }

    final decoded = await _decode(resp);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return decoded;
    }
    throw ApiException(resp.statusCode, _errorMessage(decoded), decoded);
  }

  String _errorMessage(dynamic decoded) {
    if (decoded is Map) {
      if (decoded['erreur'] != null) return decoded['erreur'].toString();
      if (decoded['detail'] != null) return decoded['detail'].toString();
      // DRF renvoie souvent {"champ": ["message"]}
      final first = decoded.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return decoded.toString();
    }
    return decoded?.toString() ?? 'Erreur inconnue';
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _request('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _request('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _request('PATCH', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _request('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) => _request('DELETE', path, auth: auth);

  /// Envoi multipart (champs texte + un fichier optionnel) — utilisé pour la
  /// photo d'un signalement (ReportCreateSerializer accepte 'photo').
  /// On passe les bytes (Uint8List, via XFile.readAsBytes()) plutôt qu'un
  /// dart:io File pour rester compatible avec le build web du dashboard.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    Uint8List? fileBytes,
    String? fileName,
    String fileField = 'photo',
    bool auth = true,
    bool retry = true,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(fields);
    if (auth) {
      final token = await accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }
    if (fileBytes != null && fileName != null) {
      request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 401 && auth && retry) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return postMultipart(path, fields: fields, fileBytes: fileBytes, fileName: fileName, fileField: fileField, auth: auth, retry: false);
      }
      await clearTokens();
      throw ApiException(401, 'Session expirée, reconnecte-toi.');
    }

    final decoded = await _decode(resp);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return decoded;
    }
    throw ApiException(resp.statusCode, _errorMessage(decoded), decoded);
  }
}
