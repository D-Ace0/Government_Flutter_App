import 'dart:convert';
import 'package:flutter/services.dart';

class ProfanityFilter {
  // Common English profanity words (as a fallback if API fails)
  static final Set<String> _englishProfanityList = {
    // Basic English offensive words
    'fuck', 'shit', 'asshole', 'bitch', 'nigga', 'nigger',
    'damn', 'bastard', 'cunt', 'dick', 'pussy', 'whore',
    'slut', 'ass', 'crap', 'piss', 'cock', 'faggot',
    'motherfucker', 'retard'
  };

  // Common Arabic profanity words (as a fallback if API fails)
  static final Set<String> _arabicProfanityList = {
    // Basic Arabic offensive words
    'كس', 'طيز', 'زب', 'خرا', 'عاهرة', 'شرموطة', 'كلب',
    'حمار', 'خنزير', 'قحبة', 'منيك', 'منيوك', 'خول',
    'عرص', 'لبوة', 'متناك', 'شاذ'
  };

  // Load additional profanity words from asset file (if exists)
  static Future<void> initialize() async {
    try {
      // Try to load additional profanity words from assets
      final String jsonData =
          await rootBundle.loadString('assets/profanity_words.json');
      final Map<String, dynamic> data = jsonDecode(jsonData);

      if (data.containsKey('english')) {
        _englishProfanityList.addAll(List<String>.from(data['english']));
      }

      if (data.containsKey('arabic')) {
        _arabicProfanityList.addAll(List<String>.from(data['arabic']));
      }
    } catch (e) {
      // If file doesn't exist or is malformed, just use the built-in lists
      print('Could not load profanity words file: $e');
    }
  }

  // Offline fallback check for profanity
  static bool containsProfanity(String text) {
    if (text.isEmpty) return false;

    // Convert to lowercase for case-insensitive matching
    final String lowerText = text.toLowerCase();

    // Remove common disguise characters
    final String normalizedText = lowerText
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll(r'$', 's')
        .replaceAll('@', 'a')
        .replaceAll('!', 'i')
        .replaceAll('*', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', ''); // Remove spaces to catch "f u c k" type evasions

    // Check English profanity - both strict word boundary and with normalized text
    for (final word in _englishProfanityList) {
      // Look for whole word matches using RegExp word boundaries
      final RegExp regex =
          RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);

      if (regex.hasMatch(lowerText)) {
        print('Profanity detected (word boundary): $word in "$text"');
        return true;
      }

      // Also check with normalized text (catches disguised profanity)
      if (normalizedText.contains(word)) {
        print('Profanity detected (normalized): $word in "$text"');
        return true;
      }
    }

    // Check Arabic profanity
    for (final word in _arabicProfanityList) {
      if (lowerText.contains(word)) {
        print('Arabic profanity detected: $word in "$text"');
        return true;
      }
    }

    // Check for common variations and abbreviations
    final Map<String, String> commonVariations = {
      'wtf': 'what the fuck',
      'stfu': 'shut the fuck up',
      'lmfao': 'laughing my fucking ass off',
      'af': 'as fuck',
      'omfg': 'oh my fucking god',
      'fkn': 'fucking',
      'fck': 'fuck',
      'fk': 'fuck',
      'sh!t': 'shit',
      'b!tch': 'bitch',
      'a\$\$': 'ass',
      'a\$\$hole': 'asshole',
      'b*tch': 'bitch',
      'f*ck': 'fuck',
      's*it': 'shit'
    };

    for (final abbreviation in commonVariations.keys) {
      if (lowerText.contains(abbreviation)) {
        print('Abbreviation profanity detected: $abbreviation in "$text"');
        return true;
      }
    }

    return false;
  }
}
