import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for the LMS backend API.
/// Uses relative URLs since the app is served via Caddy on the same origin.
///
/// Accepts an [http.Client] and [apiKey] for testability and auth.
class LmsService {
  final http.Client _client;
  final String _apiKey;

  LmsService({http.Client? client, required String apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
      };

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response =
          await _client.get(Uri.parse('/items/'), headers: _headers);
      if (response.statusCode == 200) {
        final items = jsonDecode(response.body) as List;
        return {'status': 'healthy', 'item_count': items.length};
      }
      return {'status': 'error', 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  Future<List<dynamic>> getItems() async {
    final response =
        await _client.get(Uri.parse('/items/'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<List<dynamic>> getLearners() async {
    final response =
        await _client.get(Uri.parse('/learners/'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<List<dynamic>> getPassRates(String lab) async {
    final response = await _client
        .get(Uri.parse('/analytics/pass-rates?lab=$lab'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<List<dynamic>> getScores(String lab) async {
    final response = await _client
        .get(Uri.parse('/analytics/scores?lab=$lab'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<List<dynamic>> getTimeline(String lab) async {
    final response = await _client
        .get(Uri.parse('/analytics/timeline?lab=$lab'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<List<dynamic>> getGroups(String lab) async {
    final response = await _client
        .get(Uri.parse('/analytics/groups?lab=$lab'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<List<dynamic>> getTopLearners(String lab, {int limit = 5}) async {
    final response = await _client.get(
        Uri.parse('/analytics/top-learners?lab=$lab&limit=$limit'),
        headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getCompletionRate(String lab) async {
    final response = await _client.get(
        Uri.parse('/analytics/completion-rate?lab=$lab'),
        headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<Map<String, dynamic>> syncPipeline() async {
    final response = await _client
        .post(Uri.parse('/pipeline/sync'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${response.statusCode}');
  }
}
