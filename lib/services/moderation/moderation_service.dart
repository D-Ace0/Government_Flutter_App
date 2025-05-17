import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:governmentapp/utils/profanity_filter.dart';

class ModerationService {
  static const String _tokenPath = 'assets/flutter_moderation_token.json';
  static const String _huggingfaceApiUrl =
      'https://api-inference.huggingface.co/models/Hate-speech-CNERG/arabic-english-hatespeech';

  // Private constructor for singleton pattern
  ModerationService._();
  static final ModerationService _instance = ModerationService._();

  // Singleton instance
  factory ModerationService() => _instance;

  String? _token;

  // Initialize the service by loading the token
  Future<void> initialize() async {
    try {
      // Initialize token
      final String jsonString = await rootBundle.loadString(_tokenPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _token = jsonData['huggingface_token'] as String;

      // Initialize the fallback profanity filter
      await ProfanityFilter.initialize();
    } catch (e) {
      throw Exception('Failed to load moderation token: $e');
    }
  }

  // Check if text contains offensive content
  Future<bool> containsOffensiveContent(String text) async {
    if (_token == null) {
      try {
        await initialize();
      } catch (e) {
        print('Error initializing moderation service: $e');
        // If we can't initialize the service, always fallback to local filter
      }
    }

    // Always check with local filter first for immediate detection
    final bool hasLocalOffensiveContent =
        ProfanityFilter.containsProfanity(text);
    if (hasLocalOffensiveContent) {
      print('Offensive content detected by local filter: $text');
      return true;
    }

    // Only try API if the local filter didn't detect anything and we have a token
    if (_token != null) {
      try {
        final response = await http
            .post(
              Uri.parse(_huggingfaceApiUrl),
              headers: {
                'Authorization': 'Bearer $_token',
                'Content-Type': 'application/json',
              },
              body: json.encode({'inputs': text}),
            )
            .timeout(
                const Duration(seconds: 5)); // Add timeout to prevent hanging

        if (response.statusCode == 200) {
          final dynamic result = json.decode(response.body);
          print('API Response: $result'); // Log the response for debugging

          // Handle different response formats from the model
          if (result is List && result.isNotEmpty) {
            final dynamic firstResult = result[0];

            // Handle array of scores format
            if (firstResult is List) {
              for (var item in firstResult) {
                if (item is Map<String, dynamic> &&
                    item.containsKey('label') &&
                    item.containsKey('score')) {
                  String label = item['label'].toString().toLowerCase();
                  double score = item['score'] is double ? item['score'] : 0.0;

                  print(
                      'API Label: $label, Score: $score'); // Log for debugging

                  // Check hate speech indicators with lower threshold
                  const double threshold =
                      0.3; // Lower threshold to be more strict
                  if ((label.contains('hate') ||
                          label.contains('offensive') ||
                          label.contains('profanity') ||
                          label.contains('toxic')) &&
                      score > threshold) {
                    return true;
                  }
                }
              }
            }
            // Handle single object with array of scores
            else if (firstResult is Map<String, dynamic>) {
              for (var key in firstResult.keys) {
                var item = firstResult[key];
                if (item is Map<String, dynamic> &&
                    item.containsKey('label') &&
                    item.containsKey('score')) {
                  String label = item['label'].toString().toLowerCase();
                  double score = item['score'] is double ? item['score'] : 0.0;

                  print(
                      'API Label: $label, Score: $score'); // Log for debugging

                  const double threshold = 0.3; // Lower threshold
                  if ((label.contains('hate') ||
                          label.contains('offensive') ||
                          label.contains('profanity') ||
                          label.contains('toxic')) &&
                      score > threshold) {
                    return true;
                  }
                }
              }
            }
          }
        } else {
          // If API call fails, log the error
          print('API error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Moderation API error: $e');
        // Continue with local filter result if API fails
      }
    }

    // Final fallback - check if the direct word is in the text
    // These are commonly known slurs that should always be detected regardless of API or local filter
    final hardcodedProfanity = ['nigga', 'nigger', 'fuck', 'shit', 'كس', 'طيز'];
    for (var word in hardcodedProfanity) {
      if (text.toLowerCase().contains(word.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}
