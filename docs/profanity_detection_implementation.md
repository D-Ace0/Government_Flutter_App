# Profanity Detection Implementation

## Overview
This document outlines the implementation of a robust profanity detection system for Arabic and English content in the Flutter application. The system uses multiple layers of protection to ensure inappropriate content is filtered out effectively.

## Components

### 1. Configuration Files
- `assets/flutter_moderation_token.json` - Stores the Hugging Face API token
- `assets/profanity_words.json` - Contains language-specific profanity word lists
- Both files are properly added to `.gitignore` for security

### 2. Moderation Service (`lib/services/moderation/moderation_service.dart`)
- Uses Hugging Face API for advanced language detection
- Three-layer fallback mechanism:
  - Layer 1: Hugging Face API (primary)
  - Layer 2: Local ProfanityFilter using extensive word lists
  - Layer 3: Hardcoded common offensive words as final safety net
- Properly handles API failure scenarios

### 3. Profanity Filter (`lib/utils/profanity_filter.dart`)
- Support for both Arabic and English offensive content
- Advanced detection for disguised profanity (character substitutions)
- Recognition of common abbreviations and variations
- Extendable with JSON-based word lists

### 4. Integration Points
- Chat Service: Integrated for real-time message checking
- Poll Service: Validates comments before submission
- UI Improvements: User-friendly error messages with clear dialogs

## Testing
- Comprehensive test suite in `test/moderation_test.dart`
- Tests cover:
  - Basic profanity detection in English
  - Disguised profanity with character substitutions
  - Arabic profanity detection
  - Common offensive abbreviations
  - Direct word matching fallback mechanism

## Usage
The profanity detection system is used in the following locations:
1. Chat messages (`ChatService` and `chat_room_page.dart`)
2. Poll comments (`PollService` and `poll_detail_page.dart`)

## Future Improvements
1. Add support for more languages
2. Implement machine learning for contextual understanding
3. Add admin controls to customize threshold sensitivity
4. Create moderation dashboard for reviewing flagged content
