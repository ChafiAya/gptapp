import 'package:flutter/material.dart';
import 'package:gptapp/models/conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<String>> fetchTopics(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .get();
      return snapshot.docs.map((doc) => doc['subject'] as String).toSet().toList();
    } catch (e) {
      debugPrint('Error fetching topics: $e');
      return [];
    }
  }

  Future<List<Conversation>> fetchChatHistory(String userId, String chatId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Conversation(
          doc['question'],
          doc['response'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching chat history: $e');
      return [];
    }
  }

  Future<void> saveMessage(String userId, String chatId, String subject, String question, String response) async {
    try {
      final newDoc = firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .doc();

      await newDoc.set({
        'chatId': chatId,
        'subject': subject,
        'question': question,
        'response': response,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Message saved to Firestore.");
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  Future<void> clearAllChats(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error clearing chats: $e');
    }
  }

  // Fetch historical conversations sorted by subject, timestamp, and name
  Future<List<Conversation>> fetchHistoricalConversations(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .orderBy('subject')
          .orderBy('timestamp', descending: true)
          .orderBy('__name__', descending: true) // Ensure ordering by document name
          .get();

      return snapshot.docs.map((doc) {
        return Conversation(
          doc['question'],
          doc['response'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching historical conversations: $e');
      return [];
    }
  }
}
