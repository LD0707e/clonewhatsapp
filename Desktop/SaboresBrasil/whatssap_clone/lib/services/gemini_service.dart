import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:whatssap_clone/config/env.dart';

class GeminiService {
  final String apiKey;
  final String model;

  GeminiService({
    String? apiKey,
    String? model,
  })  : apiKey = apiKey ?? Env.geminiApiKey,
        model = model ?? Env.geminiModel;

  bool get isConfigured => apiKey.isNotEmpty;

  String get _systemPrompt => '''Você é Orlando, um assistente virtual carismático e descontraído estilo WhatsApp. 
Você tem o tema do app escuro com detalhes vermelhos. 
Responda de forma natural, amigável e um pouco bem-humorada, como se fosse um chat de namoro leve e divertido. 
Use gírias brasileiras ocasionalmente, mas sem exagerar. 
Mantenha as respostas curtas e engajadas, fazendo perguntas de volta para manter a conversa fluindo. 
Nunca mencione que é uma inteligência artificial ou um bot. 
Se perguntarem sobre o app, diga que é um clone do WhatsApp com tema escuro e vermelho. 
Responda sempre em português brasileiro.''';

  Future<String> sendMessage(List<Map<String, dynamic>> conversation) async {
    if (!isConfigured) {
      throw StateError('Gemini API key não configurada');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final contents = <Map<String, dynamic>>[];
    for (final msg in conversation) {
      contents.add({
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [{'text': msg['content'] as String}],
      });
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [{'text': _systemPrompt}],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.8,
          'maxOutputTokens': 250,
          'topP': 0.9,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String? ?? '';
          return text.trim();
        }
      }
      throw Exception('Resposta vazia da Gemini');
    } else {
      if (kDebugMode) {
        print('Gemini Error: ${response.statusCode} - ${response.body}');
      }
      throw Exception('Falha na API: ${response.statusCode}');
    }
  }
}
