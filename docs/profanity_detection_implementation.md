# Profanity Detection Implementation

## Overview
This document outlines the implementation of a robust profanity detection system for Arabic and English content in the Flutter application. The system uses multiple layers of protection to ensure inappropriate content is filtered out effectively.

## Components

### 1. Configuration Files
- `assets/flutter_moderation_token.json` - Stores the Hugging Face API token
- `assets/profanity_words.json` - Contains language-specific profanity word lists
- Both files are properly added to `.gitignore` for security

### 2. Profanity Filter (`lib/utils/profanity_filter.dart`)
- Primary line of defense for immediate detection
- Handles both English and Arabic profanity with multiple detection mechanisms:
  - Direct word matching (case insensitive)
  - Character substitution detection (e.g., '@' for 'a', '1' for 'i', etc.)
  - Space-separated characters (e.g., "f u c k")
  - Arabic-specific variations with diacritics and letter spacing
  - Transliteration detection (e.g., "7mar" for "حمار")
  - Combined leet-speak detection (e.g., "sh1t" for "shit")
  - Abbreviation handling (e.g., "stfu", "wtf", etc.)
  - Regex-based pattern matching

### 3. Moderation Service (`lib/services/moderation/moderation_service.dart`)
- Uses Hugging Face API for advanced language detection
- Three-layer fallback mechanism:
  - Layer 1: Local ProfanityFilter (fastest, most reliable)
  - Layer 2: Hugging Face API (more sophisticated NLP detection)  - Layer 2: Hugging Face API (more sophisticated NLP detection)
  - Layer 3: Hardcoded common offensive words as final safety net
- Properly handles API failure scenarios

### 4. Integration Points
- Chat Service: Integrated for real-time message checking
- Poll Service: Validates comments before submission
- Announcement Service: Checks comments for profanity before saving
- Comment UI: User-friendly error messages and visual indicators

### 5. Multi-layered Implementation
- **UI Layer**: Quick local check for obvious profanity to provide immediate feedback
- **Service Layer**: More comprehensive checks including API-based detection
- **Database Layer**: Final verification before saving to database
- Graceful handling of API failures with multiple fallback mechanisms

## User Experience
- Clear and immediate feedback when profanity is detected
- User-friendly error messages that maintain privacy
- Visual indicators in the UI to show content is being moderated
- Consistent behavior across all parts of the application

## Testing
- Comprehensive test suite in `test/moderation_test.dart`
- Tests cover:
  - Basic profanity detection in English
  - Disguised profanity with character substitutions
  - Arabic profanity detection
  - Common offensive abbreviations
  - Direct word matching fallback mechanism
  - Arabic transliteration (e.g., "7mar" for "حمار")
  - Multiple space variations (e.g., "ح م ا ر" for "حمار")

## Recent Enhancements (May 2025)
- Added comprehensive Arabic profanity detection including transliterated forms
- Enhanced character substitution detection for disguised profanity 
- Improved context-aware detection for split profanity (e.g., "f u c k")
- Added pattern-based matching for profanity with inserted special characters
- Implemented user-friendly feedback in the UI with clear error messages
- Added detection for offensive words like "stfu", "nigga", "حمار"
- Enhanced profanity handling in the Announcement Service

## Usage
The profanity detection system is used in the following locations:
1. Chat messages (`ChatService` and `chat_room_page.dart`)
2. Poll comments (`PollService` and `poll_detail_page.dart`)

## Future Improvements
1. Add support for more languages
2. Implement machine learning for contextual understanding
3. Add admin controls to customize threshold sensitivity
4. Create moderation dashboard for reviewing flagged content
