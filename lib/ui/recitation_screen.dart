import 'package:flutter/material.dart';
import '../models/evaluation_model.dart';
import '../Services/tutor_state_controller.dart';
import '../Services/quran_data_service.dart';

class RecitationPracticeScreen extends StatefulWidget {
  const RecitationPracticeScreen({Key? key}) : super(key: key);

  @override
  State<RecitationPracticeScreen> createState() => _RecitationPracticeScreenState();
}

class _RecitationPracticeScreenState extends State<RecitationPracticeScreen> {
  final TutorStateController _tutorController = TutorStateController();
  final String _targetVerse = QuranDataService.getAyah(surah: 1, ayah: 1);

  @override
  void initState() {
    super.initState();
    _tutorController.addListener(_onStateChanged);
    // Start with the Qari demonstrating pronunciation automatically
    _tutorController.startQariDemonstration(_targetVerse);
  }

  @override
  void dispose() {
    _tutorController.removeListener(_onStateChanged);
    _tutorController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  /// Maps the correction status to its exact authoritative color profile
  Color _getWordColor(MatchType status, TutorState currentState) {
    if (currentState == TutorState.qariDemonstrating || currentState == TutorState.studentListening) {
      return Colors.black87; 
    }
    switch (status) {
      case MatchType.match:
        return const Color(0xFF2E7D32); // Green: Perfect match
      case MatchType.substitution:
        return const Color(0xFFE65100); // Orange: Pronunciation shift
      case MatchType.deletion:
        return const Color(0xFFC62828); // Red: Word completely skipped
      case MatchType.insertion:
        return const Color(0xFF6A1B9A); // Purple: Extra word spoken
    }
  }

  String _getStatusMessage() {
    switch (_tutorController.currentState) {
      case TutorState.qariDemonstrating:
        return "Listen closely to the Qari's pronunciation...";
      case TutorState.studentListening:
        return "Your turn! Tap the red mic button when finished reciting.";
      case TutorState.aiProcessing:
        return "Analyzing your voice data completely offline...";
      case TutorState.evaluationResult:
        return "Review feedback. Green is correct, Orange/Red needs care.";
    }
  }

  void _handleMicTap() async {
    if (_tutorController.currentState == TutorState.studentListening) {
      // Stopping the microphone and running evaluation
      // Pass a simulation string until we build the ONNX engine in Task 2
      await _tutorController.stopAndEvaluateRecitation(
        targetScript: _targetVerse,
        simulatedAIText: "بِسْمِ اللَّهِ الرحيم", // Simulating that student skipped "الرَّحْمَٰنِ"
      );
    } else if (_tutorController.currentState == TutorState.evaluationResult) {
      await _tutorController.startQariDemonstration(_targetVerse);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentState = _tutorController.currentState;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text(
          'Quran 360',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F5132),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Information Metadata Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF0F5132),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Surah Al-Fatiha, Ayah 1',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '100% Offline Mode',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),

          // The Quranic Text Interactive Display Box
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentState == TutorState.qariDemonstrating)
                      const Icon(Icons.volume_up, color: Color(0xFF0F5132), size: 32)
                    else if (currentState == TutorState.studentListening)
                      const Icon(Icons.graphic_eq, color: Colors.red, size: 32)
                    else if (currentState == TutorState.aiProcessing)
                      const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(color: Color(0xFF0F5132)))
                    else
                      const Icon(Icons.assignment_turned_in_outlined, color: Colors.blueGrey, size: 32),
                    
                    const SizedBox(height: 32),

                    // Force Right-to-Left writing mechanics for authentic script display
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Wrap(
                        spacing: 12.0,
                        runSpacing: 16.0,
                        alignment: WrapAlignment.center,
                        children: currentState == TutorState.evaluationResult
                            ? _tutorController.currentEvaluation.map((evaluation) {
                                String wordToDisplay = evaluation.targetWord ?? evaluation.recognizedWord ?? "";
                                return Text(
                                  wordToDisplay,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: _getWordColor(evaluation.status, currentState),
                                    decoration: evaluation.status == MatchType.deletion
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                );
                              }).toList()
                            : _targetVerse.split(' ').map((word) => Text(
                                word,
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black87),
                              )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Persistent Action Bar Bottom Frame
          Container(
            padding: const EdgeInsets.all(32.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusMessage(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: currentState == TutorState.studentListening ? Colors.red[700] : const Color(0xFF0F5132),
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _handleMicTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      color: currentState == TutorState.studentListening 
                          ? Colors.red[700] 
                          : currentState == TutorState.evaluationResult 
                              ? Colors.blueGrey[700]
                              : const Color(0xFF0F5132).withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (currentState == TutorState.studentListening)
                          BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, spreadRadius: 4)
                      ],
                    ),
                    child: Icon(
                      currentState == TutorState.studentListening
                          ? Icons.stop
                          : currentState == TutorState.evaluationResult
                              ? Icons.refresh
                              : Icons.mic_none,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}