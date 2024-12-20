import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gptapp/constants/colors.dart';
import 'package:gptapp/models/conversation.dart';
import 'package:gptapp/views/widgets/example_widget.dart';
import 'package:http/http.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/chat_list_view.dart';
import 'widgets/chat_text_field.dart';
import 'auth/login_page.dart';
import 'FirestoreService.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController searchController = TextEditingController();  // Controller for search
  final FirestoreService firestoreService = FirestoreService();

  List<Conversation> conversations = [];
  List<String> topics = [];
  String firstName = 'John';
  String lastName = 'Doe';
  String userId = '';
  String currentSubject = 'New Chat';
  String currentChatId = ''; // Initialize chatId as empty
  bool isSidebarOpen = false;

  bool get isConversationStarted => conversations.isNotEmpty;

  // Filtered conversations based on search query
  List<Conversation> get filteredConversations {
    final query = searchController.text.toLowerCase();
    return conversations
        .where((conversation) =>
    conversation.question.toLowerCase().contains(query) ||
        conversation.answer.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchConversationTopics();
    _startNewChat();
  }

  // Fonction pour charger les données utilisateur depuis SharedPreferences et Firebase
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      firstName = prefs.getString('firstName') ?? 'John';
      lastName = prefs.getString('lastName') ?? 'Doe';
      userId = currentUser?.uid ?? '';
    });
  }

  // Fonction pour récupérer la liste des sujets de conversation de l'utilisateur depuis Firestore
  Future<void> _fetchConversationTopics() async {
    if (userId.isEmpty) return;
    final topicsList = await firestoreService.fetchTopics(userId);
    setState(() {
      topics = topicsList;
    });
  }

  // Fonction pour récupérer l'historique des messages d'une conversation spécifique depuis Firestore
  Future<void> _fetchChatHistory(String chatId) async {
    if (userId.isEmpty) return;
    final chatHistory = await firestoreService.fetchChatHistory(userId, chatId);
    setState(() {
      conversations = chatHistory;
    });
  }

  // Fonction pour récupérer les conversations historiques de l'utilisateur depuis Firestore
  Future<void> _fetchHistoricalConversations() async {
    if (userId.isEmpty) return;
    final historicalConversations = await firestoreService.fetchHistoricalConversations(userId);
    setState(() {
      conversations = historicalConversations;
    });
  }

  // Fonction pour démarrer une nouvelle conversation, en créant un identifiant unique
  Future<void> _startNewChat() async {
    setState(() {
      currentChatId = 'chat_${DateTime.now().millisecondsSinceEpoch}'; // Unique chat ID for new chat
      currentSubject = 'New Chat';
      conversations.clear(); // Clear the conversations if it's a truly new chat.
    });

    await _fetchChatHistory(currentChatId); // Fetch the history for the new chat
  }

  // Fonction pour effacer toutes les conversations dans Firestore
  Future<void> _clearAllChats() async {
    await firestoreService.clearAllChats(userId);
    setState(() {
      topics.clear();
      conversations.clear();
    });
  }

  // Fonction pour effacer la conversation actuelle dans Firestore
  Future<void> _clearCurrentConversation() async {
    setState(() {
      conversations.clear();
    });

    try {
      final snapshot = await firestoreService.firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .where('chatId', isEqualTo: currentChatId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete(); // Delete the conversation document from Firestore
      }
      print("Conversation deleted from Firestore.");
    } catch (e) {
      debugPrint('Error clearing conversation from Firestore: $e');
    }
  }

  // Fonction pour envoyer une question à l'API et récupérer la réponse
  Future<void> _submitQuestion(String question) async {
    controller.clear();
    final currentQuestion = question ?? "";

    // Si c'est la première question de la conversation, on définit le sujet actuel
    if (conversations.isEmpty) {
      setState(() {
        currentSubject = currentQuestion;  // Set the first question as the subject
      });
    }

    if (isConversationStarted) {
      conversations.add(Conversation(currentQuestion, ""));
    } else {
      conversations = [Conversation(currentQuestion, "")];
    }
    setState(() {});

    try {
      // Envoi de la question à l'API pour obtenir la réponse
      final response = await post(
        Uri.parse("http://10.0.2.2:8000/get-response"),
        body: jsonEncode({"text": currentQuestion, "user_id": userId}),
        headers: {"Content-Type": "application/json"},
      );
      final result = jsonDecode(response.body)['response'];

      setState(() {
        conversations.last = Conversation(currentQuestion, result); // Mise à jour de la conversation avec la réponse
      });

      // Sauvegarde du message dans Firestore
      await firestoreService.saveMessage(
        userId,
        currentChatId,
        currentSubject, // Save the subject here
        currentQuestion,
        result,
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: CustomColors.background,
      appBar: AppBar(
        title: const Text('ChatGPT'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.blue.shade300,
              child: Text(
                "${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}",
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Icon for starting a new chat
          IconButton(
            icon: const Icon(Icons.chat),  // Chat icon
            onPressed: () async {
              await _startNewChat();  // Start a new chat
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await _fetchHistoricalConversations(); // Fetch historical conversations
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await _clearCurrentConversation();
              await _startNewChat();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {}); // Rebuild to filter conversations
              },
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isConversationStarted
                  ? ChatListView(conversations: filteredConversations)  // Use filtered conversations
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('Asset/images/logo.png', width: 120, height: 120),
                    const SizedBox(height: 16),
                    Text("Welcome to ChatGPT", style: textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    const ExampleWidget(text: "“Explain quantum computing in simple terms”"),
                    const ExampleWidget(text: "“Got any creative ideas for a 10 year old’s birthday?”"),
                    const ExampleWidget(text: "“How do I make an HTTP request in Javascript?”"),
                  ],
                ),
              ),
            ),
            ChatTextField(
              controller: controller,
              onSubmitted: (question) async {
                await _submitQuestion(question!);  // Handle question submission
              },
            ),
          ],
        ),
      ),
    );
  }
}
