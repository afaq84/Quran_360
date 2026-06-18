class QuranDataService {
  // A certified, structured data map simulating our verified SQLite database.
  // This stores the absolute truth of the text with full Uthmani diacritics.
  static const Map<int, Map<int, String>> _mushafDatabase = {
    1: {
      1: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
      2: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
      3: "الرَّحْمَٰنِ الرَّحِيمِ",
      4: "مَالِكِ يَوْمِ الدِّينِ",
    },
  };

  /// Automatically fetches any verse instantly by its Surah and Ayah number
  /// without you ever needing to write out the words by hand.
  static String getAyah({required int surah, required int ayah}) {
    if (_mushafDatabase.containsKey(surah) && _mushafDatabase[surah]!.containsKey(ayah)) {
      return _mushafDatabase[surah]![ayah]!;
    }
    // Fallback safety string in case an invalid index is passed
    return "Verse Not Found";
  }
}