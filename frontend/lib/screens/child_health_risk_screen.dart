import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/health_risk_model.dart';
import '../services/health_risk_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class ChildHealthRiskScreen extends StatefulWidget {
  const ChildHealthRiskScreen({Key? key}) : super(key: key);

  @override
  State<ChildHealthRiskScreen> createState() => _ChildHealthRiskScreenState();
}

class _ChildHealthRiskScreenState extends State<ChildHealthRiskScreen> {
  final HealthRiskPredictionService _riskService =
      HealthRiskPredictionService();

  // Form values
  final _formKey = GlobalKey<FormState>();
  int _childAge = 5;
  String _childGender = 'Male';
  double? _childHeight;
  double? _childWeight;

  // Selected conditions and factors
  final List<ParentalHealthCondition> _selectedConditions = [];
  final List<LifestyleFactor> _selectedFactors = [];

  // Prediction results
  HealthRiskPrediction? _prediction;
  bool _isCalculating = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    // Add some default lifestyle factors
    _selectedFactors.add(_riskService.commonLifestyleFactors
        .firstWhere((factor) => factor.name == 'Regular Physical Activity'));
    _selectedFactors.add(_riskService.commonLifestyleFactors
        .firstWhere((factor) => factor.name == 'Balanced Diet'));
  }

  Future<void> _calculateRisks() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCalculating = true;
        _showResults = false;
      });

      try {
        final profile = ChildHealthProfile(
          age: _childAge,
          gender: _childGender,
          height: _childHeight,
          weight: _childWeight,
          parentalConditions: _selectedConditions,
          lifestyleFactors: _selectedFactors,
        );

        final prediction = await _riskService.predictHealthRisks(profile);

        setState(() {
          _prediction = prediction;
          _showResults = true;
          _isCalculating = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating health risks: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Child Health Risk')),
        backgroundColor: AppTheme.turquoise,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _showResults ? _buildResultsView() : _buildInputForm(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.turquoise),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('About this tool'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                          'This tool helps estimate potential health risks for children based on parental conditions and lifestyle factors. The results are for informational purposes only and should not replace professional medical advice.'),
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Child Details Section
            Text(
              context.tr('Child Details'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Age Slider
            Row(
              children: [
                const Text('Age:'),
                Expanded(
                  child: Slider(
                    value: _childAge.toDouble(),
                    min: 1,
                    max: 18,
                    divisions: 17,
                    activeColor: AppTheme.turquoise,
                    inactiveColor: AppTheme.paleBlue,
                    label: _childAge.toString(),
                    onChanged: (value) {
                      setState(() {
                        _childAge = value.round();
                      });
                    },
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text('$_childAge'),
                ),
              ],
            ),

            // Gender Selection
            Row(
              children: [
                const Text('Gender:'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'Male',
                  groupValue: _childGender,
                  activeColor: AppTheme.turquoise,
                  onChanged: (value) {
                    setState(() {
                      _childGender = value!;
                    });
                  },
                ),
                const Text('Male'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'Female',
                  groupValue: _childGender,
                  activeColor: AppTheme.turquoise,
                  onChanged: (value) {
                    setState(() {
                      _childGender = value!;
                    });
                  },
                ),
                const Text('Female'),
              ],
            ),

            // Optional Height and Weight inputs (side by side)
            Row(
              children: [
                // Height Input
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: context.tr('Height (cm)'),
                      hintText: context.tr('Optional'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _childHeight = double.tryParse(value);
                        });
                      } else {
                        setState(() {
                          _childHeight = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Weight Input
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: context.tr('Weight (kg)'),
                      hintText: context.tr('Optional'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _childWeight = double.tryParse(value);
                        });
                      } else {
                        setState(() {
                          _childWeight = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Parental Health Conditions Section
            Text(
              context.tr('Parental Health Conditions'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context
                  .tr('Select all conditions that apply to biological parents'),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Conditions Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _riskService.commonParentalConditions.map((condition) {
                final isSelected = _selectedConditions
                    .any((selected) => selected.name == condition.name);

                return FilterChip(
                  label: Text(condition.name),
                  selected: isSelected,
                  selectedColor: AppTheme.turquoise.withOpacity(0.2),
                  checkmarkColor: AppTheme.turquoise,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConditions.add(condition);
                      } else {
                        _selectedConditions
                            .removeWhere((c) => c.name == condition.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Lifestyle Factors Section
            Text(
              context.tr('Lifestyle Factors'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                  'Select all that apply to the child\'s current lifestyle'),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Lifestyle Factors Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _riskService.commonLifestyleFactors.map((factor) {
                final isSelected = _selectedFactors
                    .any((selected) => selected.name == factor.name);

                return FilterChip(
                  label: Text(factor.name),
                  selected: isSelected,
                  selectedColor: AppTheme.paleBlue.withOpacity(0.3),
                  checkmarkColor: AppTheme.turquoise,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFactors.add(factor);
                      } else {
                        _selectedFactors
                            .removeWhere((f) => f.name == factor.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.turquoise,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                onPressed: _isCalculating ? null : _calculateRisks,
                child: _isCalculating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        context.tr('Calculate Health Risks'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_prediction == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Risk Score Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppTheme.paleBlue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    context.tr('Overall Health Risk Score'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: CircularProgressIndicator(
                            value: _prediction!.overallRiskScore,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getRiskColor(_prediction!.overallRiskScore),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_prediction!.overallRiskScore * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getRiskLevelText(_prediction!.overallRiskScore),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: _getRiskColor(
                                    _prediction!.overallRiskScore),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Risk Categories Section
          Text(
            context.tr('Risk Categories'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Risk Categories List
          ..._prediction!.riskCategories
              .map((category) => _buildRiskCategoryCard(category)),
          const SizedBox(height: 24),

          // Recommendations Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppTheme.turquoise),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('Recommendations'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._prediction!.recommendations
                      .map((recommendation) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 20, color: AppTheme.turquoise),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recommendation,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: Text(
              context.tr(
                  'Disclaimer: This assessment is for informational purposes only and does not constitute medical advice. Always consult with healthcare professionals for proper medical guidance.'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reset Button
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Start New Assessment')),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.turquoise,
              ),
              onPressed: () {
                setState(() {
                  _showResults = false;
                  _prediction = null;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRiskCategoryCard(RiskCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getRiskColor(category.riskScore).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category name and risk level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskColor(category.riskScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getRiskColor(category.riskScore).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getRiskLevelText(category.riskScore),
                    style: TextStyle(
                      color: _getRiskColor(category.riskScore),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              category.description,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            // Potential Diseases Section
            if (category.potentialDiseases.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                context.tr('Potential Associated Conditions:'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              ...category.potentialDiseases
                  .map((disease) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                disease.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _getRiskColor(disease.riskFactor)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRiskColor(disease.riskFactor)
                                      .withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${(disease.riskFactor * 100).toInt()}% ' +
                                    context.tr('Risk'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getRiskColor(disease.riskFactor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],

            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: category.riskScore,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _getRiskColor(category.riskScore)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(double score) {
    if (score < 0.3) return Colors.green;
    if (score < 0.7) return Colors.orange;
    return Colors.red;
  }

  String _getRiskLevelText(double score) {
    if (score < 0.3) return context.tr('Low Risk');
    if (score < 0.7) return context.tr('Moderate Risk');
    return context.tr('High Risk');
  }
}
