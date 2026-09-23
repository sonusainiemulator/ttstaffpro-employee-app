import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum KioskVoiceLanguage {
  hindi,
  english,
  mute,
}

/// Text-to-speech voice feedback engine for attendance punch greetings.
class KioskTTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  KioskVoiceLanguage _language = KioskVoiceLanguage.hindi;
  bool _isEnabled = true;

  KioskVoiceLanguage get language => _language;
  bool get isEnabled => _isEnabled;

  Future<void> init({KioskVoiceLanguage language = KioskVoiceLanguage.hindi, bool enabled = true}) async {
    _language = language;
    _isEnabled = enabled;

    if (!_isEnabled || _language == KioskVoiceLanguage.mute) return;

    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);

      if (_language == KioskVoiceLanguage.hindi) {
        await _tts.setLanguage('hi-IN');
      } else {
        await _tts.setLanguage('en-US');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization warning: $e');
    }
  }

  void setLanguage(KioskVoiceLanguage language) {
    _language = language;
    _applyLanguage();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  Future<void> _applyLanguage() async {
    if (!_isInitialized) return;
    try {
      if (_language == KioskVoiceLanguage.hindi) {
        await _tts.setLanguage('hi-IN');
      } else if (_language == KioskVoiceLanguage.english) {
        await _tts.setLanguage('en-US');
      }
    } catch (_) {}
  }

  /// Speaks a customized greeting after a successful punch.
  Future<void> speakPunchSuccess({
    required String employeeName,
    required String action, // 'check_in', 'check_out', 'attendance'
    bool isOffline = false,
  }) async {
    if (!_isEnabled || _language == KioskVoiceLanguage.mute) return;

    try {
      if (!_isInitialized) {
        await init(language: _language, enabled: _isEnabled);
      }

      final String cleanName = employeeName.trim().split(' ').first;
      String message = '';

      if (_language == KioskVoiceLanguage.hindi) {
        if (action.toLowerCase().contains('in') || action == 'check_in') {
          message = 'नमस्ते $cleanName जी, आपकी उपस्थिति दर्ज कर ली गई है। आपका दिन शुभ हो!';
        } else if (action.toLowerCase().contains('out') || action == 'check_out') {
          message = 'धन्यवाद $cleanName जी, चेक आउट दर्ज हो गया है। आपका दिन अच्छा रहे!';
        } else {
          message = 'नमस्ते $cleanName जी, हाजिरी लग चुकी है। धन्यवाद!';
        }
      } else {
        if (action.toLowerCase().contains('in') || action == 'check_in') {
          message = 'Welcome $cleanName, check-in recorded. Have a great day!';
        } else if (action.toLowerCase().contains('out') || action == 'check_out') {
          message = 'Goodbye $cleanName, check-out recorded. Have a great evening!';
        } else {
          message = 'Welcome $cleanName, attendance marked successfully!';
        }
      }

      await _tts.stop();
      await _tts.speak(message);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Speaks prompt when an unknown face or error occurs.
  Future<void> speakPrompt(String textHindi, String textEnglish) async {
    if (!_isEnabled || _language == KioskVoiceLanguage.mute) return;
    try {
      final text = _language == KioskVoiceLanguage.hindi ? textHindi : textEnglish;
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

final KioskTTSService kioskTTSService = KioskTTSService();
