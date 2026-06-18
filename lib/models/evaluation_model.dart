/// Represents the four distinct states of correctness for a recited word
enum MatchType {
  match,         // Word matched the Quranic text perfectly
  substitution,  // Word was mispronounced or a vowel/diacritic changed
  deletion,      // Word was present in the text but skipped by the student
  insertion      // Student spoke an extra word not present in the text
}

/// A highly precise wrapper tracking the exact evaluation of an individual word
class WordEvaluation {
  final String? targetWord;     // The perfect word from the Uthmani script DB
  final String? recognizedWord; // What the offline AI model heard the student say
  final MatchType status;       // The explicit classification label

  WordEvaluation({
    this.targetWord,
    this.recognizedWord,
    required this.status,
  });
}