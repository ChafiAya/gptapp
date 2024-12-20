import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gptapp/models/conversation.dart';

class ConversationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> saveConversation(String userId, String subject, List<Conversation> conversations) async {
    try {
      WriteBatch batch = firestore.batch();
      for (var conversation in conversations) {
        final newDoc = firestore
            .collection('users')
            .doc(userId)
            .collection('conversations')
            .doc();
        batch.set(newDoc, {
          'subject': subject,
          'question': conversation.question,
          'response': conversation.answer,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      print("Conversations saved to Firestore.");
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  Future<List<String>> fetchTopics(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .get();
      return snapshot.docs.map((doc) => doc['subject'] as String).toSet().toList();
    } catch (e) {
      print('Error fetching topics: $e');
      return [];
    }
  }

  Future<List<Conversation>> fetchChatHistory(String userId, String subject) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .where('subject', isEqualTo: subject)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Conversation(
          doc['question'],
          doc['response'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
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
      print('Error clearing chats: $e');
    }
  }
}
