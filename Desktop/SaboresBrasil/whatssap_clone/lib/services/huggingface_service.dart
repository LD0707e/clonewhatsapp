import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:whatssap_clone/config/env.dart';

class HuggingFaceService {
  final String token;
  final String model;
  late final String _baseUrl;

  HuggingFaceService({
    String? token,
    String? model,
  })  : token = token ?? Env.huggingFaceToken,
        model = model ?? Env.huggingFaceModel {
    _baseUrl = 'https://api-inference.huggingface.co/models/$model';
  }

  bool get isConfigured => token.isNotEmpty;

  String get _systemPrompt => '''Você é Orlando, um assistente virtual carismático e descontraído estilo WhatsApp. 
Você tem o tema do app escuro com detalhes vermelhos. 
Responda de forma natural, amigável e um pouco bem-humorada, como se fosse um chat de namoro leve e divertido. 
Use gírias brasileiras ocasionalmente, mas sem exagerar. 
Mantenha as respostas curtas e engajadas, fazendo perguntas de volta para manter a conversa fluindo. 
Nunca mencione que é uma inteligência artificial ou um bot. 
Se perguntarem sobre o app, diga que é um clone do WhatsApp com tema escuro e vermelho. 
Responda sempre em português brasileiro.''';

  String _buildPrompt(List<Map<String, dynamic>> conversation) {
    final buffer = StringBuffer();
    buffer.writeln('[$_systemPrompt]');
    buffer.writeln('=== Conversa ===');
    for (final msg in conversation) {
      final role = msg['role'] == 'user' ? 'Usuário' : 'Orlando';
      buffer.writeln('$role: ${msg['content']}');
    }
    buffer.writeln('Orlando:');
    return buffer.toString();
  }

  String _extractReply(String generated, String prompt) {
    if (generated.length > prompt.length) {
      final afterPrompt = generated.substring(prompt.length).trim();
      if (afterPrompt.isNotEmpty) return afterPrompt;
    }
    final idx = generated.lastIndexOf('Orlando:');
    if (idx != -1) {
      return generated.substring(idx + 'Orlando:'.length).trim();
    }
    return generated.trim();
  }

  Future<String> sendMessage(List<Map<String, dynamic>> conversation) async {
    if (!isConfigured) {
      throw StateError('HuggingFace token não configurada');
    }

    final prompt = _buildPrompt(conversation);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': 250,
          'temperature': 0.8,
          'top_p': 0.9,
          'do_sample': true,
          'return_full_text': false,
        },
        'options': {
          'wait_for_model': true,
          'use_cache': true,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        final generated = data[0]['generated_text'] as String? ??
            data[0]['generated_text'].toString();
        return _extractReply(generated, prompt);
      }

      if (data is Map && data['generated_text'] != null) {
        final generated = data['generated_text'].toString();
        return _extractReply(generated, prompt);
      }

      if (data is String) {
        return _extractReply(data, prompt);
      }

      throw Exception('Formato de resposta inesperado da HuggingFace');
    } else if (response.statusCode == 503) {
      throw Exception(
          'Modelo carregando... Tente novamente em alguns segundos.');
    } else {
      final body = jsonDecode(response.body);
      if (kDebugMode) {
        print('HuggingFace Error: ${response.statusCode} - $body');
      }
      throw Exception('Erro na API: ${response.statusCode}');
    }
  }
}
