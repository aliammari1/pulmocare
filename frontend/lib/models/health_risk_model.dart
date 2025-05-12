import 'dart:convert';

class ParentalHealthCondition {
  final String name;
  final bool isHereditary;
  final double riskFactor;

  ParentalHealthCondition({
    required this.name,
    required this.isHereditary,
    required this.riskFactor,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isHereditary': isHereditary,
      'riskFactor': riskFactor,
    };
  }

  // Create from JSON
  factory ParentalHealthCondition.fromJson(Map<String, dynamic> json) {
    return ParentalHealthCondition(
      name: json['name'],
      isHereditary: json['isHereditary'],
      riskFactor: json['riskFactor'],
    );
  }
}

class LifestyleFactor {
  final String name;
  final String category; // 'diet', 'activity', 'environment', etc.
  final double impact; // -1.0 to 1.0 (negative is bad, positive is good)

  LifestyleFactor({
    required this.name,
    required this.category,
    required this.impact,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'impact': impact,
    };
  }

  // Create from JSON
  factory LifestyleFactor.fromJson(Map<String, dynamic> json) {
    return LifestyleFactor(
      name: json['name'],
      category: json['category'],
      impact: json['impact'],
    );
  }
}

class HealthRiskPrediction {
  final List<RiskCategory> riskCategories;
  final double overallRiskScore;
  final List<String> recommendations;

  HealthRiskPrediction({
    required this.riskCategories,
    required this.overallRiskScore,
    required this.recommendations,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'riskCategories': riskCategories.map((c) => c.toJson()).toList(),
      'overallRiskScore': overallRiskScore,
      'recommendations': recommendations,
    };
  }

  // Create from JSON
  factory HealthRiskPrediction.fromJson(Map<String, dynamic> json) {
    return HealthRiskPrediction(
      riskCategories: (json['riskCategories'] as List)
          .map((c) => RiskCategory.fromJson(c))
          .toList(),
      overallRiskScore: json['overallRiskScore'],
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}

class DiseasePotential {
  final String name;
  final double riskFactor;

  DiseasePotential({
    required this.name,
    required this.riskFactor,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'riskFactor': riskFactor,
    };
  }

  // Create from JSON
  factory DiseasePotential.fromJson(Map<String, dynamic> json) {
    return DiseasePotential(
      name: json['name'],
      riskFactor: json['riskFactor'],
    );
  }
}

class RiskCategory {
  final String name;
  final double riskScore; // 0.0 to 1.0
  final String description;
  final List<DiseasePotential> potentialDiseases;

  RiskCategory({
    required this.name,
    required this.riskScore,
    required this.description,
    this.potentialDiseases = const [],
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'riskScore': riskScore,
      'description': description,
      'potentialDiseases':
          potentialDiseases.map((disease) => disease.toJson()).toList(),
    };
  }

  // Create from JSON
  factory RiskCategory.fromJson(Map<String, dynamic> json) {
    return RiskCategory(
      name: json['name'],
      riskScore: json['riskScore'],
      description: json['description'],
      potentialDiseases: json['potentialDiseases'] != null
          ? (json['potentialDiseases'] as List)
              .map((disease) => DiseasePotential.fromJson(disease))
              .toList()
          : [],
    );
  }

  // Get risk level text
  String get riskLevelText {
    if (riskScore < 0.3) return 'Low';
    if (riskScore < 0.7) return 'Moderate';
    return 'High';
  }

  // Get risk level color (as a string)
  String get riskLevelColor {
    if (riskScore < 0.3) return '#4CAF50'; // Green
    if (riskScore < 0.7) return '#FFC107'; // Amber
    return '#F44336'; // Red
  }
}

class ChildHealthProfile {
  final int age;
  final String gender;
  final double? height; // In cm
  final double? weight; // In kg
  final List<ParentalHealthCondition> parentalConditions;
  final List<LifestyleFactor> lifestyleFactors;

  ChildHealthProfile({
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    required this.parentalConditions,
    required this.lifestyleFactors,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'parentalConditions':
          parentalConditions.map((condition) => condition.toJson()).toList(),
      'lifestyleFactors':
          lifestyleFactors.map((factor) => factor.toJson()).toList(),
    };
  }

  // Create from JSON
  factory ChildHealthProfile.fromJson(Map<String, dynamic> json) {
    return ChildHealthProfile(
      age: json['age'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      parentalConditions: (json['parentalConditions'] as List)
          .map((c) => ParentalHealthCondition.fromJson(c))
          .toList(),
      lifestyleFactors: (json['lifestyleFactors'] as List)
          .map((f) => LifestyleFactor.fromJson(f))
          .toList(),
    );
  }
}
