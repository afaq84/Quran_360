import '../models/evaluation_model.dart';

class QuranAlignmentEngine {
  // Regex block targeting Arabic diacritics (Harakat) for clean baseline matching
  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u0652\u0670]');

  /// Normalizes Arabic text by removing vowels/diacritics for raw text matching.
  static String normalizeArabic(String text) {
    return text.replaceAll(_diacriticsRegex, '').trim();
  }

  /// Evaluates speech input against the flawless target verse text word-by-word.
  static List<WordEvaluation> analyzeRecitation({
    required String targetVerse,
    required String recognizedSpeech,
  }) {
    // Split the text strings cleanly into lists of distinct words
    List<String> targetTokens = targetVerse.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    List<String> spokenTokens = recognizedSpeech.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    int n = targetTokens.length;
    int m = spokenTokens.length;

    // Mathematical scoring weights for global sequence processing
    const int matchReward = 2;
    const int mismatchPenalty = -1;
    const int gapPenalty = -2;

    // Initialize the two-dimensional scoring matrix grid with zeros
    List<List<int>> matrix = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    // Seed the baseline boundary penalty cells
    for (int i = 0; i <= n; i++) matrix[i][0] = i * gapPenalty;
    for (int j = 0; j <= m; j++) matrix[0][j] = j * gapPenalty;

    // Dynamically calculate intersection cell values across the entire grid
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        bool isMatch = normalizeArabic(targetTokens[i - 1]) == normalizeArabic(spokenTokens[j - 1]);
        
        int matchScore = matrix[i - 1][j - 1] + (isMatch ? matchReward : mismatchPenalty);
        int deleteScore = matrix[i - 1][j] + gapPenalty;
        int insertScore = matrix[i][j - 1] + gapPenalty;

        matrix[i][j] = [matchScore, deleteScore, insertScore].reduce((max, val) => val > max ? val : max);
      }
    }

    // Backtrack backward from the bottom-right corner to identify mistake classifications
    List<WordEvaluation> resultsPath = [];
    int i = n;
    int j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        bool isMatch = normalizeArabic(targetTokens[i - 1]) == normalizeArabic(spokenTokens[j - 1]);
        if (matrix[i][j] == matrix[i - 1][j - 1] + (isMatch ? matchReward : mismatchPenalty)) {
          resultsPath.add(WordEvaluation(
            targetWord: targetTokens[i - 1],
            recognizedWord: spokenTokens[j - 1],
            status: isMatch ? MatchType.match : MatchType.substitution,
          ));
          i--; j--;
          continue;
        }
      }
      
      if (i > 0 && (j == 0 || matrix[i][j] == matrix[i - 1][j] + gapPenalty)) {
        // The word exists in the Quran script but was completely skipped in speech
        resultsPath.add(WordEvaluation(
          targetWord: targetTokens[i - 1],
          recognizedWord: null,
          status: MatchType.deletion,
        ));
        i--;
      } else if (j > 0 && (i == 0 || matrix[i][j] == matrix[i][j - 1] + gapPenalty)) {
        // An extra, unprescribed word was inserted into the recitation
        resultsPath.add(WordEvaluation(
          targetWord: null,
          recognizedWord: spokenTokens[j - 1],
          status: MatchType.insertion,
        ));
        j--;
      }
    }

    // Reverse the backtracked collection to display words in reading order
    return resultsPath.reversed.toList();
  }
}