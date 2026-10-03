import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Groq settings, read from the Firestore doc `config/ai` so the model and
/// key can be changed from the Firebase console without shipping a build.
///
/// Expected fields: `apiKey` (string, required), `model` (string,
/// required), and optionally `enabled` (bool, default true),
/// `temperature` (number, default 0.7), `maxTokens` (number, default 400)
/// and `baseUrl` (default Groq's OpenAI-compatible endpoint).
class AiConfig {
  final String apiKey;
  final String model;
  final String baseUrl;
  final double temperature;
  final int maxTokens;

  const AiConfig({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
    required this.temperature,
    required this.maxTokens,
  });

  static AiConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null || json['enabled'] == false) return null;
    final key = (json['apiKey'] as String?)?.trim() ?? '';
    final model = (json['model'] as String?)?.trim() ?? '';
    if (key.isEmpty || model.isEmpty) return null;
    return AiConfig(
      apiKey: key,
      model: model,
      baseUrl: (json['baseUrl'] as String?)?.trim().isNotEmpty == true
          ? json['baseUrl'] as String
          : 'https://api.groq.com/openai/v1',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 400,
    );
  }
}

class AiMessage {
  final String role; // system | user | assistant
  final String content;

  const AiMessage(this.role, this.content);

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// The app's single AI entry point. Every call returns null instead of
/// throwing when the config is missing or Groq fails, so callers can fall
/// back to their local, rule-based text.
class AiService {
  AiService._();
  static final instance = AiService._();

  AiConfig? _config;
  DateTime? _fetchedAt;

  Future<AiConfig?> _loadConfig() async {
    // Refetch every 10 minutes so console changes (new key, new model)
    // reach running apps without a restart.
    final fresh = _fetchedAt != null && DateTime.now().difference(_fetchedAt!) < const Duration(minutes: 10);
    if (fresh) return _config;
    try {
      final snap = await FirebaseFirestore.instance.collection('config').doc('ai').get();
      _config = AiConfig.fromJson(snap.data());
      _fetchedAt = DateTime.now();
    } catch (e) {
      debugPrint('AiService: could not read config/ai — $e');
    }
    return _config;
  }

  Future<String?> chat(List<AiMessage> messages, {int? maxTokens}) async {
    final config = await _loadConfig();
    if (config == null) return null;
    try {
      final res = await http
          .post(
            Uri.parse('${config.baseUrl}/chat/completions'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': config.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'temperature': config.temperature,
              'max_tokens': maxTokens ?? config.maxTokens,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        debugPrint('AiService: Groq ${res.statusCode} — ${res.body}');
        // A bad key/model shouldn't stay cached for 10 minutes.
        if (res.statusCode == 401 || res.statusCode == 404) _fetchedAt = null;
        return null;
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = (body['choices'] as List?)?.firstOrNull?['message']?['content'] as String?;
      final text = content?.trim();
      return (text == null || text.isEmpty) ? null : text;
    } catch (e) {
      debugPrint('AiService: request failed — $e');
      return null;
    }
  }
}
