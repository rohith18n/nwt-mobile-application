class Category {
  final String id;
  final String name;
  final String? parentId; // null for main categories, id of parent for subcategories

  Category({
    required this.id,
    required this.name,
    this.parentId,
  });
}
