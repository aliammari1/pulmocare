import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/health_risk_model.dart';
import '../services/gemini_service.dart';

class HealthRiskPredictionService {
  final GeminiService _geminiService = GeminiService();

  // Common parental conditions with hereditary risk factors
  final List<ParentalHealthCondition> commonParentalConditions = [
    ParentalHealthCondition(
        name: 'Diabetes Type 2', isHereditary: true, riskFactor: 0.7),
    ParentalHealthCondition(
        name: 'Hypertension', isHereditary: true, riskFactor: 0.6),
    ParentalHealthCondition(
        name: 'Asthma', isHereditary: true, riskFactor: 0.65),
    ParentalHealthCondition(
        name: 'Coronary Heart Disease', isHereditary: true, riskFactor: 0.5),
    ParentalHealthCondition(
        name: 'Obesity', isHereditary: true, riskFactor: 0.7),
    ParentalHealthCondition(
        name: 'Depression', isHereditary: true, riskFactor: 0.4),
    ParentalHealthCondition(
        name: 'Cancer', isHereditary: true, riskFactor: 0.3),
    ParentalHealthCondition(
        name: 'Allergies', isHereditary: true, riskFactor: 0.6),
  ];

  final List<LifestyleFactor> commonLifestyleFactors = [
    LifestyleFactor(
        name: 'Regular Physical Activity', category: 'activity', impact: 0.8),
    LifestyleFactor(name: 'Balanced Diet', category: 'diet', impact: 0.7),
    LifestyleFactor(name: 'Adequate Sleep', category: 'lifestyle', impact: 0.6),
    LifestyleFactor(
        name: 'Low Screen Time', category: 'lifestyle', impact: 0.4),
    LifestyleFactor(
        name: 'Regular Health Checkups', category: 'healthcare', impact: 0.5),
    LifestyleFactor(
        name: 'Low Exposure to Pollution',
        category: 'environment',
        impact: 0.3),
    LifestyleFactor(
        name: 'No Exposure to Smoking', category: 'environment', impact: 0.7),
    LifestyleFactor(
        name: 'Stress Management', category: 'mental health', impact: 0.5),
  ];

  // Get health risk prediction using local calculations
  Future<HealthRiskPrediction> predictHealthRisks(
      ChildHealthProfile profile) async {
    // In a real app, this would be a call to a backend API
    // For now, we'll implement a simple prediction model locally

    try {
      // Calculate risk categories
      List<RiskCategory> riskCategories = _calculateRiskCategories(profile);

      // Calculate overall risk
      double overallRiskScore = _calculateOverallRiskScore(riskCategories);

      // Generate recommendations
      List<String> recommendations =
          await _generateRecommendations(profile, riskCategories);

      return HealthRiskPrediction(
        riskCategories: riskCategories,
        overallRiskScore: overallRiskScore,
        recommendations: recommendations,
      );
    } catch (e) {
      print('Error predicting health risks: $e');
      throw Exception('Failed to predict health risks: $e');
    }
  }

  // Calculate risk categories based on profile
  List<RiskCategory> _calculateRiskCategories(ChildHealthProfile profile) {
    // Calculate BMI-based risk if height and weight are available
    List<RiskCategory> categories = [];

    // Physical health risks
    double physicalHealthRisk = 0.3; // Base risk
    List<DiseasePotential> physicalDiseases = [];

    // Add risk based on parental conditions
    for (var condition in profile.parentalConditions) {
      if (condition.isHereditary) {
        physicalHealthRisk += condition.riskFactor * 0.1;

        // Add condition as potential disease if it's relevant to physical health
        if ([
          'Diabetes Type 2',
          'Hypertension',
          'Asthma',
          'Coronary Heart Disease',
          'Obesity',
          'Cancer',
          'Allergies'
        ].contains(condition.name)) {
          double diseaseRisk = condition.riskFactor * 0.7; // Scale the risk
          physicalDiseases.add(DiseasePotential(
            name: condition.name,
            riskFactor: diseaseRisk.clamp(0.0, 1.0),
          ));
        }
      }
    }

    // Adjust based on positive lifestyle factors
    for (var factor in profile.lifestyleFactors) {
      if (factor.impact > 0) {
        physicalHealthRisk -= factor.impact * 0.05;
      } else {
        physicalHealthRisk += factor.impact.abs() * 0.05;
      }
    }

    // Ensure value is between 0 and 1
    physicalHealthRisk = physicalHealthRisk.clamp(0.0, 1.0);

    // Create physical health risk category
    categories.add(RiskCategory(
      name: 'Physical Health',
      riskScore: physicalHealthRisk,
      description:
          'Risk of developing physical health issues based on hereditary and lifestyle factors',
      potentialDiseases: physicalDiseases,
    ));

    // Mental health risks
    double mentalHealthRisk = 0.2; // Base risk
    List<DiseasePotential> mentalDiseases = [];

    // Add risk based on relevant parental conditions
    for (var condition in profile.parentalConditions) {
      if (condition.name == 'Depression' ||
          condition.name == 'Anxiety' ||
          condition.name == 'ADHD') {
        mentalHealthRisk += condition.riskFactor * 0.15;

        // Add condition as potential disease for mental health
        double diseaseRisk = condition.riskFactor * 0.8; // Scale the risk
        mentalDiseases.add(DiseasePotential(
          name: condition.name,
          riskFactor: diseaseRisk.clamp(0.0, 1.0),
        ));
      }
    }

    // Add other common mental health conditions with lower risk if no specific conditions
    if (mentalDiseases.isEmpty) {
      if (mentalHealthRisk > 0.4) {
        mentalDiseases.add(DiseasePotential(
          name: 'Anxiety Disorders',
          riskFactor: (mentalHealthRisk * 0.7).clamp(0.0, 1.0),
        ));
        mentalDiseases.add(DiseasePotential(
          name: 'Depression',
          riskFactor: (mentalHealthRisk * 0.6).clamp(0.0, 1.0),
        ));
      }
    }

    // Adjust based on relevant lifestyle factors
    for (var factor in profile.lifestyleFactors) {
      if (factor.category == 'mental health' ||
          factor.category == 'lifestyle') {
        if (factor.impact > 0) {
          mentalHealthRisk -= factor.impact * 0.08;
        } else {
          mentalHealthRisk += factor.impact.abs() * 0.08;
        }
      }
    }

    // Ensure value is between 0 and 1
    mentalHealthRisk = mentalHealthRisk.clamp(0.0, 1.0);

    // Create mental health risk category
    categories.add(RiskCategory(
      name: 'Mental Health',
      riskScore: mentalHealthRisk,
      description:
          'Risk of developing mental health issues based on hereditary and lifestyle factors',
      potentialDiseases: mentalDiseases,
    ));

    // Dietary/nutritional risks
    double nutritionRisk = 0.3; // Base risk
    List<DiseasePotential> nutritionDiseases = [];

    // Adjust based on relevant parental conditions
    for (var condition in profile.parentalConditions) {
      if (condition.name == 'Diabetes Type 2' || condition.name == 'Obesity') {
        nutritionRisk += condition.riskFactor * 0.1;

        // Add condition as potential disease for nutrition
        double diseaseRisk = condition.riskFactor * 0.75; // Scale the risk
        nutritionDiseases.add(DiseasePotential(
          name: condition.name,
          riskFactor: diseaseRisk.clamp(0.0, 1.0),
        ));
      } else if (condition.name == 'Allergies') {
        // Add food allergies as a potential issue
        nutritionDiseases.add(DiseasePotential(
          name: 'Food Allergies',
          riskFactor: (condition.riskFactor * 0.5).clamp(0.0, 1.0),
        ));
      }
    }

    // Add other common nutritional issues based on overall risk
    if (nutritionRisk > 0.5 &&
        !nutritionDiseases.any((d) => d.name == 'Obesity')) {
      nutritionDiseases.add(DiseasePotential(
        name: 'Obesity',
        riskFactor: (nutritionRisk * 0.8).clamp(0.0, 1.0),
      ));
    }

    if (nutritionRisk > 0.4 &&
        !nutritionDiseases.any((d) => d.name == 'Nutrient Deficiencies')) {
      nutritionDiseases.add(DiseasePotential(
        name: 'Nutrient Deficiencies',
        riskFactor: (nutritionRisk * 0.7).clamp(0.0, 1.0),
      ));
    }

    // Adjust based on diet lifestyle factors
    for (var factor in profile.lifestyleFactors) {
      if (factor.category == 'diet') {
        if (factor.impact > 0) {
          nutritionRisk -= factor.impact * 0.15;
        } else {
          nutritionRisk += factor.impact.abs() * 0.15;
        }
      }
    }

    // Ensure value is between 0 and 1
    nutritionRisk = nutritionRisk.clamp(0.0, 1.0);

    // Create nutrition risk category
    categories.add(RiskCategory(
      name: 'Nutrition & Diet',
      riskScore: nutritionRisk,
      description: 'Risk of developing nutritional issues or disorders',
      potentialDiseases: nutritionDiseases,
    ));

    return categories;
  }

  // Calculate overall risk score
  double _calculateOverallRiskScore(List<RiskCategory> riskCategories) {
    if (riskCategories.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (var category in riskCategories) {
      totalScore += category.riskScore;
    }

    return (totalScore / riskCategories.length).clamp(0.0, 1.0);
  }

  // Generate recommendations using Gemini AI
  Future<List<String>> _generateRecommendations(
      ChildHealthProfile profile, List<RiskCategory> riskCategories) async {
    try {
      // Create a prompt for Gemini
      String prompt = '''
Generate 5 specific health recommendations for a ${profile.age} year old ${profile.gender} child with the following risk profile:
${riskCategories.map((c) => '- ${c.name}: ${c.riskLevelText} risk').join('\n')}

Parental health conditions: ${profile.parentalConditions.map((c) => c.name).join(', ')}

Current lifestyle factors: ${profile.lifestyleFactors.map((f) => f.name).join(', ')}

Format each recommendation as a brief, actionable item that parents can implement.
''';

      // Get response from Gemini
      String response = await _geminiService.getMedicalResponse(prompt);

      // Parse recommendations (assuming they come as a numbered or bulleted list)
      List<String> recommendations = [];

      // Simple parsing of numbered items
      final pattern = RegExp(r'^\d+\.?\s*(.+)$', multiLine: true);
      final matches = pattern.allMatches(response);

      // If we found numbered items, extract them
      if (matches.isNotEmpty) {
        for (var match in matches) {
          if (match.group(1) != null) {
            recommendations.add(match.group(1)!.trim());
          }
        }
      } else {
        // Fallback to splitting by newlines if there are no numbered items
        recommendations = response
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^[-•*]\s*'), '').trim())
            .where((line) => line.length > 10) // Only keep meaningful lines
            .take(5) // Take at most 5
            .toList();
      }

      // If we still couldn't extract recommendations, provide default ones
      if (recommendations.isEmpty) {
        recommendations = [
          'Schedule regular pediatric checkups to monitor development',
          'Encourage daily physical activity for at least 60 minutes',
          'Ensure a balanced diet with plenty of fruits and vegetables',
          'Establish consistent sleep routines with age-appropriate duration',
          'Limit screen time and promote educational activities',
        ];
      }

      return recommendations;
    } catch (e) {
      print('Error generating recommendations: $e');
      // Return default recommendations if AI generation fails
      return [
        'Schedule regular pediatric checkups to monitor development',
        'Encourage daily physical activity for at least 60 minutes',
        'Ensure a balanced diet with plenty of fruits and vegetables',
        'Establish consistent sleep routines with age-appropriate duration',
        'Limit screen time and promote educational activities',
      ];
    }
  }
}
