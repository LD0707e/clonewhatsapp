import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:whatssap_clone/config/env.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  final String apiKey;
  final String model;

  OpenAIService({
    String? apiKey,
    String? model,
  })  : apiKey = apiKey ?? Env.openAIApiKey,
        model = model ?? Env.openAIModel;

  bool get isConfigured => apiKey.isNotEmpty;

  String get _systemPrompt => '''Você é Orlando, um assistente virtual carismático e descontraído estilo WhatsApp. 
Você tem o tema do app escuro com detalhes vermelhos. 
Responda de forma natural, amigável e um pouco bem-humorada, como se fosse um chat de namoro leve e divertido. 
Use gírias brasileiras ocasionalmente, mas sem exagerar. 
Mantenha as respostas curtas e engajadas, fazendo perguntas de volta para manter a conversa fluindo. 
Nunca mencione que é uma inteligência artificial ou um bot. 
Se perguntarem sobre o app, diga que é um clone do WhatsApp com tema escuro e vermelho. 
Responda sempre em português brasileiro.''';

  Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    if (!isConfigured) {
      throw StateError('API key não configurada');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...messages,
          ],
          'max_tokens': 200,
          'temperature': 0.8,
          'top_p': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        final error = jsonDecode(response.body);
        if (kDebugMode) {
          print('OpenAI Error: $error');
        }
        throw Exception('Falha na API: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI Exception: $e');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  List<Map<String, dynamic>> buildMessage(
    String text, {
    bool isUser = true,
  }) {
    return [
      {
        'role': isUser ? 'user' : 'assistant',
        'content': text,
      },
    ];
  }
}
