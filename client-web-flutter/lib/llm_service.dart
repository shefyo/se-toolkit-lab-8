import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lms_service.dart';

/// LLM client with tool-calling loop.
/// Mirrors the Python bot's intent_router.py.
///
/// Accepts an [http.Client] for testability.
class LlmService {
  final http.Client _client;

  LlmService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiUrl =
      '/utils/qwen-code-api/v1/chat/completions';

  static const String _model = 'coder-model';

  static const String systemPrompt =
      'You are an assistant for an LMS (Learning Management System) bot. '
      'Your job is to help users get information about labs, scores, learners, and system status.\n\n'
      'You have access to tools that fetch data from the LMS backend. '
      'When a user asks a question, determine which tool(s) to call based on their intent.\n\n'
      'Common intents:\n'
      '- "Is the system working?" / "health check" -> get_health\n'
      '- "What labs are available?" / "show labs" -> get_labs\n'
      '- "Show scores for lab-X" / "pass rates" -> get_scores (requires lab parameter)\n'
      '- "Who are the top students?" -> get_top_learners (requires lab parameter)\n'
      '- "When did students submit?" -> get_timeline (requires lab parameter)\n'
      '- "How did groups perform?" -> get_groups (requires lab parameter)\n'
      '- "What\'s the completion rate?" -> get_completion_rate (requires lab parameter)\n'
      '- "Sync the data" -> sync_pipeline\n\n'
      'If the user\'s query is missing required parameters (like lab name), ask them to provide it.\n'
      'Always be concise and helpful in your responses.';

  static final List<Map<String, dynamic>> tools = [
    {
      'type': 'function',
      'function': {
        'name': 'get_health',
        'description':
            'Check if the LMS backend is healthy and get the item count',
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_labs',
        'description':
            'List all available labs with their names and descriptions',
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_scores',
        'description': 'Get pass rates for tasks within a specific lab',
        'parameters': {
          'type': 'object',
          'properties': {
            'lab': {
              'type': 'string',
              'description':
                  "The lab identifier (e.g., 'lab-04', 'lab-01')",
            },
          },
          'required': ['lab'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_learners',
        'description': 'Get list of all enrolled learners',
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_timeline',
        'description':
            'Get submission timeline for a specific lab showing submissions per day',
        'parameters': {
          'type': 'object',
          'properties': {
            'lab': {
              'type': 'string',
              'description': "The lab identifier (e.g., 'lab-04')",
            },
          },
          'required': ['lab'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_groups',
        'description':
            'Get per-group performance metrics for a specific lab',
        'parameters': {
          'type': 'object',
          'properties': {
            'lab': {
              'type': 'string',
              'description': "The lab identifier (e.g., 'lab-04')",
            },
          },
          'required': ['lab'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_top_learners',
        'description': 'Get top performing learners for a specific lab',
        'parameters': {
          'type': 'object',
          'properties': {
            'lab': {
              'type': 'string',
              'description': "The lab identifier (e.g., 'lab-04')",
            },
            'limit': {
              'type': 'integer',
              'description':
                  'Number of top learners to return (default: 5)',
              'default': 5,
            },
          },
          'required': ['lab'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_completion_rate',
        'description':
            'Get the completion rate percentage for a specific lab',
        'parameters': {
          'type': 'object',
          'properties': {
            'lab': {
              'type': 'string',
              'description': "The lab identifier (e.g., 'lab-04')",
            },
          },
          'required': ['lab'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'sync_pipeline',
        'description':
            'Trigger the ETL pipeline to sync data from the source',
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
  ];

  Future<Map<String, dynamic>> _chat(
    List<Map<String, dynamic>> messages, {
    List<Map<String, dynamic>>? toolDefs,
  }) async {
    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
    };
    if (toolDefs != null) {
      body['tools'] = toolDefs;
      body['tool_choice'] = 'auto';
    }

    final response = await _client.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('LLM API error: HTTP ${response.statusCode}');
  }

  Future<dynamic> _executeTool(
    String name,
    Map<String, dynamic> args,
    LmsService lms,
  ) async {
    switch (name) {
      case 'get_health':
        return await lms.healthCheck();
      case 'get_labs':
        return await lms.getItems();
      case 'get_scores':
        return await lms.getPassRates(args['lab'] ?? '');
      case 'get_learners':
        return await lms.getLearners();
      case 'get_timeline':
        return await lms.getTimeline(args['lab'] ?? '');
      case 'get_groups':
        return await lms.getGroups(args['lab'] ?? '');
      case 'get_top_learners':
        return await lms.getTopLearners(
          args['lab'] ?? '',
          limit: args['limit'] ?? 5,
        );
      case 'get_completion_rate':
        return await lms.getCompletionRate(args['lab'] ?? '');
      case 'sync_pipeline':
        return await lms.syncPipeline();
      default:
        return 'Unknown tool: $name';
    }
  }

  /// Route a natural language message through the LLM with tool calling.
  Future<String> routeIntent(String userMessage, LmsService lms) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _chat(messages, toolDefs: tools);
      final message =
          response['choices'][0]['message'] as Map<String, dynamic>;

      if (message.containsKey('tool_calls') &&
          message['tool_calls'] != null &&
          (message['tool_calls'] as List).isNotEmpty) {
        final toolCall = message['tool_calls'][0] as Map<String, dynamic>;
        final function_ = toolCall['function'] as Map<String, dynamic>;
        final functionName = function_['name'] as String;
        var functionArgs = function_['arguments'];

        if (functionArgs is String) {
          functionArgs = jsonDecode(functionArgs) as Map<String, dynamic>;
        }

        final result = await _executeTool(
          functionName,
          functionArgs as Map<String, dynamic>,
          lms,
        );

        messages.add(message);
        messages.add({
          'role': 'tool',
          'tool_call_id': toolCall['id'],
          'content': jsonEncode(result),
        });

        final finalResponse = await _chat(messages);
        return finalResponse['choices'][0]['message']['content'] as String;
      } else {
        return message['content'] as String? ??
            "I'm not sure how to help with that. Try /help for available commands.";
      }
    } catch (e) {
      return 'Error processing your request: $e';
    }
  }
}
