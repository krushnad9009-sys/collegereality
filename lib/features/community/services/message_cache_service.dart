import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message_model.dart';

/// Lightweight offline cache for the most recent chat messages per conversation.
class MessageCacheService {
  MessageCacheService._();

  static const _prefix = 'chat_cache_v1_';
  static const _maxMessages = 40;

  static Future<void> saveMessages(
    String conversationId,
    List<ChatMessageModel> messages,
  ) async {
    if (conversationId.isEmpty || messages.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final slice = messages.take(_maxMessages).map((m) => m.toJson()).toList();
    await prefs.setString('$_prefix$conversationId', jsonEncode(slice));
  }

  static Future<List<ChatMessageModel>> loadMessages(
    String conversationId,
  ) async {
    if (conversationId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$conversationId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
