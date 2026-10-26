import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// REST client for the Lost & Found server (Postgres on Neon behind Express).
/// On the web the app is served by the same server, so the API lives at the
/// same origin. For mobile builds pass --dart-define=API_BASE_URL=https://...
class Api {
  static const String _configuredBase = String.fromEnvironment('API_BASE_URL');
  static const Duration _timeout = Duration(seconds: 60); // Render cold start

  static String? _token;
  static Map<String, dynamic>? me;

  /// Increment to make feeds reload (after posting, editing, saving...).
  static final ValueNotifier<int> postsChanged = ValueNotifier<int>(0);
  static void notifyPostsChanged() => postsChanged.value++;

  static String get baseUrl {
    if (_configuredBase.isNotEmpty) {
      return _configuredBase.replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return Uri.base.origin;
    throw ApiException('API_BASE_URL is not configured for this build.');
  }

  static bool get isSignedIn => (_token ?? '').isNotEmpty && me != null;
  static String get myId => (me?['id'] ?? '').toString();

  /// Restores the saved session (call once before runApp).
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if ((_token ?? '').isNotEmpty) {
        try {
          me = Map<String, dynamic>.from(await _request('GET', '/users/me'));
        } on ApiException catch (e) {
          if (e.status == 401) await signOut();
        }
      }
    } catch (_) {
      // offline or server asleep: start on the sign-in page
    }
  }

  static Future<void> _saveToken(String? t) async {
    _token = t;
    final prefs = await SharedPreferences.getInstance();
    if (t == null) {
      await prefs.remove('token');
    } else {
      await prefs.setString('token', t);
    }
  }

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl/api$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if ((_token ?? '').isNotEmpty) 'Authorization': 'Bearer $_token',
    };
    http.Response r;
    try {
      switch (method) {
        case 'POST':
          r = await http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(_timeout);
          break;
        case 'PUT':
          r = await http.put(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(_timeout);
          break;
        case 'DELETE':
          r = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          r = await http.get(uri, headers: headers).timeout(_timeout);
      }
    } catch (_) {
      throw ApiException('Cannot reach the server. Please try again.');
    }
    dynamic data;
    try {
      data = jsonDecode(r.body);
    } catch (_) {
      data = null;
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Request failed (${r.statusCode}).';
      throw ApiException(msg, r.statusCode);
    }
    return data;
  }

  static List<Map<String, dynamic>> _list(dynamic d) =>
      (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  static Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);

  // ---- auth
  static Future<void> signUp(String email, String username, String password) async {
    final d = _map(await _request('POST', '/auth/signup',
        body: {'email': email, 'username': username, 'password': password}));
    await _saveToken(d['token'] as String);
    me = _map(d['user']);
  }

  static Future<void> login(String email, String password) async {
    final d = _map(await _request('POST', '/auth/login',
        body: {'email': email, 'password': password}));
    await _saveToken(d['token'] as String);
    me = _map(d['user']);
  }

  static Future<void> signOut() async {
    me = null;
    await _saveToken(null);
  }

  static Future<void> changePassword(String current, String next) async {
    await _request('PUT', '/auth/password',
        body: {'currentPassword': current, 'newPassword': next});
  }

  // ---- users
  static Future<Map<String, dynamic>> getMe() async {
    me = _map(await _request('GET', '/users/me'));
    return me!;
  }

  static Future<Map<String, dynamic>> getUser(String id) async =>
      _map(await _request('GET', '/users/$id'));

  static Future<List<Map<String, dynamic>>> users() async =>
      _list(await _request('GET', '/users'));

  static Future<Map<String, dynamic>> updateMe(String username, String bio, String avatarURL) async {
    me = _map(await _request('PUT', '/users/me',
        body: {'username': username, 'bio': bio, 'avatarURL': avatarURL}));
    return me!;
  }

  // ---- posts
  static Future<List<Map<String, dynamic>>> posts({String? authorId}) async =>
      _list(await _request('GET', authorId == null ? '/posts' : '/posts?authorId=$authorId'));

  static Future<List<Map<String, dynamic>>> savedPosts() async =>
      _list(await _request('GET', '/posts/saved'));

  static Future<Map<String, dynamic>> createPost(String description, String imageURL) async =>
      _map(await _request('POST', '/posts',
          body: {'description': description, 'imageURL': imageURL}));

  static Future<Map<String, dynamic>> updatePost(
          String id, String description, String imageURL, bool isResolved) async =>
      _map(await _request('PUT', '/posts/$id', body: {
        'description': description,
        'imageURL': imageURL,
        'isResolved': isResolved,
      }));

  static Future<void> deletePost(String id) => _request('DELETE', '/posts/$id');

  static Future<Map<String, dynamic>> setLike(String id, bool like) async =>
      _map(await _request(like ? 'POST' : 'DELETE', '/posts/$id/like'));

  static Future<Map<String, dynamic>> setSaved(String id, bool save) async =>
      _map(await _request(save ? 'POST' : 'DELETE', '/posts/$id/save'));

  // ---- comments
  static Future<List<Map<String, dynamic>>> comments(String postId) async =>
      _list(await _request('GET', '/posts/$postId/comments'));

  static Future<void> addComment(String postId, String text) =>
      _request('POST', '/posts/$postId/comments', body: {'text': text});
}
