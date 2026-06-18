import 'package:flutter/material.dart';
import '../models/evaluation_model.dart';
import 'alignment_engine.dart';

/// The 4 distinct logical states for the Quran 360 interactive practice flow.
enum TutorState {
  qariDemonstrating, // Reference Qari/Mawlana audio track is currently playing
  studentListening,   // App microphone stream is actively capturing the student's voice
  aiProcessing,      // Local on-device Whisper AI is decoding audio frames to text
  evaluationResult   // UI presents precise color-coded recitation feedback
}

class TutorStateController with ChangeNotifier {
  TutorState _currentState = TutorState.qariDemonstrating;
  List<WordEvaluation> _currentEvaluation = [];

  // Public getters to safely expose current state conditions to the UI layer
  TutorState get currentState => _currentState;
  List<WordEvaluation> get currentEvaluation => _currentEvaluation;

  /// Transition 1: Initiates the selected Qari/Mawlana audio instruction segment.
  Future<void> startQariDemonstration(String targetVerse) async {
    _currentState = TutorState.qariDemonstrating;
    notifyListeners();

    print("Playing reference Qari audio file completely offline...");
    // Future integration anchor: Link local audio playback engine plugin here
    await Future.delayed(const Duration(seconds: 3)); // Simulating audio playback duration

    // The precise millisecond the Qari concludes, hand control over to the student
    moveToStudentListening();
  }

  /// Transition 2: Automatically activates the native smartphone microphone.
  void moveToStudentListening() {
    _currentState = TutorState.studentListening;
    notifyListeners();
    print("Microphone active stream open. Capturing student recitation...");
    // Future integration anchor: Initialize 16kHz PCM voice recording buffer here
  }

  /// Transitions 3 & 4: Feeds audio inputs to the matrix engine and yields results.
  void evaluateStudentRecitation({
    required String targetScript,
    required String localWhisperOutput,
  }) {
    _currentState = TutorState.aiProcessing;
    notifyListeners();

    // Pass the clean text streams into our Needleman-Wunsch sequence matrix
    final results = QuranAlignmentEngine.analyzeRecitation(
      targetVerse: targetScript,
      recognizedSpeech: localWhisperOutput,
    );

    _currentEvaluation = results;

    // Scan the matrix output array to see if any words were omitted or substituted
    bool hasErrors = results.any((word) =>
        word.status == MatchType.substitution ||
        word.status == MatchType.deletion);

    _currentState = TutorState.evaluationResult;
    notifyListeners();

    if (!hasErrors) {
      print("MashaAllah! Perfect recitation match. Ready to advance.");
      // Future hook: Automatically unlock and fetch next database indexing segment
    } else {
      print("Deviation detected. State machine prepares to repeat pronunciation track.");
      // Future hook: Re-trigger target verse audio block sequence for specific corrections
    }
  }
}