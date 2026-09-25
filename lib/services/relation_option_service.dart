/// Service class for managing family relation options
class RelationOptionService {
  /// Get the list of available family relation types
  static List<String> getRelationOptions() {
    return [
      'Spouse',
      'Child',
      'Parent',
      'Sibling',
      'Grandparent',
      'Grandchild',
      'Uncle/Aunt',
      'Niece/Nephew',
      'Cousin',
      'In-law',
      'Other',
    ];
  }

  /// Get a relation option by index
  static String? getRelationByIndex(int index) {
    final options = getRelationOptions();
    if (index >= 0 && index < options.length) {
      return options[index];
    }
    return null;
  }

  /// Check if a relation option exists
  static bool hasRelation(String relation) {
    return getRelationOptions().contains(relation);
  }
}
