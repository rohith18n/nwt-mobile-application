class Nominee {
  final String name;
  final String relation;
  final double sharepercentage;
  final bool? isprimary;

  Nominee({
    required this.name,
    required this.relation,
    required this.sharepercentage,
    this.isprimary,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      name: json['name'] ?? '',
      relation: json['relation'] ?? '',
      sharepercentage: (json['sharepercentage'] ?? 0).toDouble(),
      isprimary: json['isprimary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relation': relation,
      'sharepercentage': sharepercentage,
      if (isprimary != null) 'isprimary': isprimary,
    };
  }

  @override
  String toString() {
    return 'Nominee(name: $name, relation: $relation, sharepercentage: $sharepercentage, isprimary: $isprimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Nominee &&
        other.name == name &&
        other.relation == relation &&
        other.sharepercentage == sharepercentage &&
        other.isprimary == isprimary;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        relation.hashCode ^
        sharepercentage.hashCode ^
        isprimary.hashCode;
  }
}
