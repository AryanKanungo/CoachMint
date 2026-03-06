// lib/services/chat_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

// ─────────────────────────────────────────────────────────────
// ChatException — public so ai_agent_screen.dart can catch it
// ─────────────────────────────────────────────────────────────
class ChatException implements Exception {
  final int statusCode;
  final String message;

  const ChatException({required this.statusCode, required this.message});

  @override
  String toString() => 'ChatException($statusCode): $message';
}

// ─────────────────────────────────────────────────────────────
// ChatService — single async method, throws ChatException
// ─────────────────────────────────────────────────────────────
class ChatService {
  // ─── PLACEHOLDER: Replace with your real backend URL before deployment ───
  // Local Android emulator: 'http://10.0.2.2:8000'
  // Local iOS simulator:    'http://127.0.0.1:8000'
  // Deployed backend:       'https://your-backend.railway.app'
  static const String _baseUrl = 'https://proglottidean-addyson-malapertly.ngrok-free.dev';
  // ─────────────────────────────────────────────────────────────────────────

  static const String _endpoint = '$_baseUrl/api/chat';
  static const Duration _timeout = Duration(seconds: 10);

  Future<ChatApiResponse> sendMessage({
    required String userId,
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'message': message,
              'history': history,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json =
            jsonDecode(response.body) as Map<String, dynamic>;
            print(  'ChatService received response: $json'); // Debug log
        return ChatApiResponse.fromJson(json);
      } else if (response.statusCode == 502) {
        throw const ChatException(
            statusCode: 502, message: 'Bad gateway');
      } else if (response.statusCode >= 500) {
        throw ChatException(
            statusCode: response.statusCode,
            message: 'Server error ${response.statusCode}');
      } else {
        throw ChatException(
            statusCode: response.statusCode,
            message: 'Unexpected status ${response.statusCode}');
      }
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw const ChatException(statusCode: 0, message: 'timeout');
    } on SocketException {
      throw const ChatException(statusCode: 0, message: 'network');
    } on http.ClientException {
      throw const ChatException(statusCode: 0, message: 'timeout');
    } catch (_) {
      throw const ChatException(
          statusCode: -1, message: 'unknown');
    }
  }
}
