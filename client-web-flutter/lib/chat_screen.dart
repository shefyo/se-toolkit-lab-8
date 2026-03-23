import 'package:flutter/material.dart';
import 'lms_service.dart';
import 'llm_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _apiKey;
  LmsService? _lms;
  late final LlmService _llm = LlmService();
  bool _isLoading = false;

  static const _commands = [
    ('/start', 'Welcome'),
    ('/help', 'Help'),
    ('/health', 'Health'),
    ('/labs', 'Labs'),
    ('/scores lab-04', 'Scores'),
    ('/sync', 'Sync Pipeline'),
  ];

  void _connect(String apiKey) {
    setState(() {
      _apiKey = apiKey;
      _lms = LmsService(apiKey: apiKey);
      _messages.clear();
    });
    _addBotMessage(
      'Welcome to SE Toolkit Bot!\n\n'
      'I can help you check system health, browse labs, view scores, '
      'and answer questions about your LMS data.\n\n'
      'Use the buttons below or type a command like /help.',
    );
  }

  void _disconnect() {
    setState(() {
      _apiKey = null;
      _lms = null;
      _messages.clear();
      _apiKeyController.clear();
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    String response;
    if (trimmed.startsWith('/')) {
      response = await _handleCommand(trimmed);
    } else {
      response = await _llm.routeIntent(trimmed, _lms!);
    }

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<String> _handleCommand(String input) async {
    final parts = input.split(RegExp(r'\s+'));
    final command = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    switch (command) {
      case '/start':
        return 'Welcome to SE Toolkit Bot!\n\n'
            'I\'m your LMS assistant. I can help you:\n'
            '- Check system health with /health\n'
            '- Browse available labs with /labs\n'
            '- View scores with /scores <lab>\n'
            '- Ask questions in plain language!\n\n'
            'Type /help to see all available commands.';

      case '/help':
        return 'Available commands:\n\n'
            '- /start - Welcome message\n'
            '- /help - Show this help message\n'
            '- /health - Check backend system status\n'
            '- /labs - List all available labs\n'
            '- /scores <lab> - View pass rates for a specific lab\n\n'
            'You can also ask questions in plain language, like:\n'
            '- "What labs are available?"\n'
            '- "Show me the scores for lab-04"\n'
            '- "Is the backend working?"';

      case '/health':
        try {
          final result = await _lms!.healthCheck();
          if (result['status'] == 'healthy') {
            return 'Backend is healthy. ${result['item_count']} items available.';
          }
          return 'Backend error: ${result['error']}';
        } catch (e) {
          return 'Error checking health: $e';
        }

      case '/labs':
        try {
          final items = await _lms!.getItems();
          final labs = items
              .where((item) => item['type'] == 'lab')
              .toList()
            ..sort((a, b) =>
                a['id'].toString().compareTo(b['id'].toString()));

          if (labs.isEmpty) return 'No labs available.';

          final buffer = StringBuffer('Available labs:\n\n');
          for (final lab in labs) {
            buffer.writeln('- ${lab['title']}');
          }
          return buffer.toString().trim();
        } catch (e) {
          return 'Error fetching labs: $e';
        }

      case '/scores':
        if (args.isEmpty) {
          return 'Please specify a lab. Usage: /scores <lab>\nExample: /scores lab-04';
        }
        try {
          final passRates = await _lms!.getPassRates(args[0]);
          if (passRates.isEmpty) {
            return 'No scores found for ${args[0]}. Check the lab name.';
          }

          final buffer = StringBuffer('Pass rates for ${args[0]}:\n\n');
          for (final rate in passRates) {
            final task = rate['task'] ?? 'Unknown';
            final avgScore = (rate['avg_score'] as num?)?.toStringAsFixed(1) ?? '0';
            final attempts = rate['attempts'] ?? 0;
            buffer.writeln('- $task: $avgScore% ($attempts attempts)');
          }
          return buffer.toString().trim();
        } catch (e) {
          final msg = e.toString();
          if (msg.contains('404') || msg.toLowerCase().contains('not found')) {
            return 'Lab \'${args[0]}\' not found. Check the lab name.';
          }
          return 'Error fetching scores: $msg';
        }

      case '/sync':
        try {
          final result = await _lms!.syncPipeline();
          return 'Pipeline sync complete. '
              '${result['new_records'] ?? 0} new records, '
              '${result['total_records'] ?? 0} total records.';
        } catch (e) {
          return 'Error syncing pipeline: $e';
        }

      default:
        return 'Unknown command: $command. Type /help for available commands.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_apiKey == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('LMS API Key',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Enter your LMS API key to connect.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Token',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) _connect(value.trim());
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final key = _apiKeyController.text.trim();
                      if (key.isNotEmpty) _connect(key);
                    },
                    child: const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LMS Chatbot'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _disconnect,
            child: const Text('Disconnect',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildCommandMenu(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const SizedBox(
          width: 48,
          height: 24,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommandMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _commands.map((cmd) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                label: Text(cmd.$2),
                onPressed: _isLoading ? null : () => _sendMessage(cmd.$1),
                backgroundColor: Colors.white,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message or command...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: _sendMessage,
              enabled: !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed:
                _isLoading ? null : () => _sendMessage(_controller.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
