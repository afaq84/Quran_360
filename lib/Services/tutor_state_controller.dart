import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/evaluation_model.dart';
import 'alignment_engine.dart';

/// The 4 distinct logical states for the Quran 360 interactive practice flow.
enum TutorState {
  qariDemonstrating, // Reference Qari audio track is currently playing
  studentListening,   // App microphone stream is actively capturing the student's voice
  aiProcessing,      // Local on-device AI is decoding audio frames
  evaluationResult   // UI presents precise color-coded recitation feedback
}

class TutorStateController with ChangeNotifier {
  TutorState _currentState = TutorState.qariDemonstrating;
  List<WordEvaluation> _currentEvaluation = [];
  
  // Hardware Interface Instances
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedAudioPath;

  // Public getters to safely expose current state conditions to the UI layer
  TutorState get currentState => _currentState;
  List<WordEvaluation> get currentEvaluation => _currentEvaluation;
  String? get recordedAudioPath => _recordedAudioPath;

  /// Transition 1: Initiates the selected Qari/Mawlana audio instruction segment.
  Future<void> startQariDemonstration(String targetVerse) async {
    _currentState = TutorState.qariDemonstrating;
    notifyListeners();

    print("Playing reference Qari audio track completely offline...");
    await Future.delayed(const Duration(seconds: 3)); // Simulating audio playback duration

    // Clean handoff to student recording once demonstration concludes
    await startStudentRecording();
  }

  /// Transition 2: Requests system permissions and initializes microphone stream.
  Future<void> startStudentRecording() async {
    try {
      // Check and request microphone permission from Android/iOS safely
      if (!await _audioRecorder.hasPermission()) {
        print("Microphone access denied by the user.");
        return;
      }

      // Establish a clean physical path in local application directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      _recordedAudioPath = '${appDocDir.path}/student_recitation.wav';

      // Strict Audio Configuration: 16kHz, Mono, PCM 16-bit 
      // This is the absolute worldwide standard format required by offline AI engines like Whisper
      const RecordConfig recordingConfiguration = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Fire up the microphone hardware stream
      await _audioRecorder.start(recordingConfiguration, path: _recordedAudioPath!);
      
      _currentState = TutorState.studentListening;
      notifyListeners();
      print("Microphone active stream open at: $_recordedAudioPath");
    } catch (e) {
      print("Fatal error initializing audio hardware layers: $e");
    }
  }

  /// Transitions 3 & 4: Halts hardware stream and passes parameters to alignment engine
  Future<void> stopAndEvaluateRecitation({
    required String targetScript,
    required String simulatedAIText, // Placeholder until Task 2 loads local ONNX engine
  }) async {
    _currentState = TutorState.aiProcessing;
    notifyListeners();

    try {
      // Close down the physical microphone hardware layer safely
      final String? absoluteFilePath = await _audioRecorder.stop();
      print("Audio capture sequence finalized. Wave file closed at: $absoluteFilePath");

      // Pass the text parameters into our Needleman-Wunsch sequence engine
      final results = QuranAlignmentEngine.analyzeRecitation(
        targetVerse: targetScript,
        recognizedSpeech: simulatedAIText,
      );

      _currentEvaluation = results;

      // Scan the resulting matrix structure array to see if any mistakes exist
      bool hasErrors = results.any((word) =>
          word.status == MatchType.substitution ||
          word.status == MatchType.deletion);

      _currentState = TutorState.evaluationResult;
      notifyListeners();

      if (!hasErrors) {
        print("MashaAllah! Perfect recitation match.");
      } else {
        print("Deviation detected. Ready to loop track or flag segment.");
      }
    } catch (e) {
      print("Error finalizing audio capture evaluation tracking: $e");
      _currentState = TutorState.studentListening;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose(); // Always clear hardware links out of device memory
    super.dispose();
  }
}