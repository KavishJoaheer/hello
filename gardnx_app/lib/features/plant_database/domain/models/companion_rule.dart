class CompanionRule {
  final String id;
  final String plantAId;
  final String plantBId;
  final CompanionType type;
  final String reason;
  final double strengthScore; // 0.0 - 1.0

  const CompanionRule({
    required this.id,
    required this.plantAId,
    required this.plantBId,
    required this.type,
    required this.reason,
    this.strengthScore = 0.8,
  });

  factory CompanionRule.fromJson(Map<String, dynamic> json) => CompanionRule(
        id: json['id'] as String? ?? '',
        plantAId: json['plant_a_id'] as String,
        plantBId: json['plant_b_id'] as String,
        type: CompanionTypeExt.fromValue(json['type'] as String? ?? 'companion'),
        reason: json['reason'] as String? ?? '',
        strengthScore: (json['strength_score'] as num? ?? 0.8).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plant_a_id': plantAId,
        'plant_b_id': plantBId,
        'type': type.value,
        'reason': reason,
        'strength_score': strengthScore,
      };

  /// Returns true if this rule involves both given plant IDs (in any order).
  bool involves(String plantId1, String plantId2) =>
      (plantAId == plantId1 && plantBId == plantId2) ||
      (plantAId == plantId2 && plantBId == plantId1);

  /// Returns the partner plant id relative to [plantId].
  String? partnerOf(String plantId) {
    if (plantAId == plantId) return plantBId;
    if (plantBId == plantId) return plantAId;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CompanionRule && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

enum CompanionType { companion, incompatible, neutral }

extension CompanionTypeExt on CompanionType {
  String get value {
    switch (this) {
      case CompanionType.companion:
        return 'companion';
      case CompanionType.incompatible:
        return 'incompatible';
      case CompanionType.neutral:
        return 'neutral';
    }
  }

  String get label {
    switch (this) {
      case CompanionType.companion:
        return 'Good Companion';
      case CompanionType.incompatible:
        return 'Incompatible';
      case CompanionType.neutral:
        return 'Neutral';
    }
  }

  static CompanionType fromValue(String value) {
    switch (value) {
      case 'companion':
        return CompanionType.companion;
      case 'incompatible':
        return CompanionType.incompatible;
      default:
        return CompanionType.neutral;
    }
  }
}
