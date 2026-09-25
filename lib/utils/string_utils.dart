/// Utility class for string manipulation and formatting
class StringUtils {
  /// Capitalizes the first letter of the string
  /// Example: "hello" -> "Hello"
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Capitalizes the first letter of each word in the string
  /// Example: "hello world" -> "Hello World"
  static String capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Converts the string to title case (capitalizes first letter of each word except articles, 
  /// prepositions, and conjunctions unless they are the first word)
  /// Example: "the quick brown fox" -> "The Quick Brown Fox"
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    final List<String> smallWords = [
      'a', 'an', 'and', 'as', 'at', 'but', 'by', 'for', 'if', 'in', 
      'nor', 'of', 'on', 'or', 'so', 'the', 'to', 'up', 'yet'
    ];
    
    return text.split(' ').asMap().entries.map((entry) {
      final int idx = entry.key;
      final String word = entry.value;
      
      if (idx == 0 || !smallWords.contains(word.toLowerCase())) {
        return capitalize(word);
      }
      return word.toLowerCase();
    }).join(' ');
  }

  /// Converts the string to sentence case (capitalizes only the first letter of the first word)
  /// Example: "hello world. how are you?" -> "Hello world. How are you?"
  static String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    
    // Split by sentence terminators (.!?) followed by space or end of string
    final sentences = text.split(RegExp(r'([.!?]+\s*|$)'));
    final terminators = text.split(RegExp(r'[^.!?]+'));
    
    String result = '';
    for (int i = 0; i < sentences.length; i++) {
      if (sentences[i].isNotEmpty) {
        result += capitalize(sentences[i].trim());
      }
      if (i < terminators.length) {
        result += terminators[i];
      }
    }
    
    return result;
  }

  /// Truncates the string to the specified length and adds ellipsis if needed
  /// Example: "Hello World".truncate(7) -> "Hello..."
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }
}
