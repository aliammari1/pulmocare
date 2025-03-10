import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/medical_report.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/color_picker.dart';

class ReportEditorScreen extends StatefulWidget {
  final MedicalReport? report;

  const ReportEditorScreen({super.key, this.report});

  @override
  State<ReportEditorScreen> createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends State<ReportEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>> _annotations = [];
  Color _currentDrawingColor = Colors.black;
  double _currentStrokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report?.title ?? '');
    _contentController =
        TextEditingController(text: widget.report?.content ?? '');
    _annotations =
        widget.report?.annotations.map((a) => a.toJson()).toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _analyzeReport() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final provider = context.read<ReportProvider>();
      final analysis = await provider.analyzeReport(_contentController.text);
      setState(() {
        _isAnalyzing = false;
        _analysis = analysis;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing report: $e')),
        );
      }
    }
  }

  void _handleDrawingComplete(List<CanvasPoint> points) async {
    try {
      final annotation = Annotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        x: 0,
        y: 0,
        width: 0,
        height: 0,
        color: 0,
      );

      if (widget.report != null) {
        final provider = context.read<ReportProvider>();
        await provider.addAnnotation(widget.report!.id, annotation);
      } else {
        setState(() {
          _annotations.add(annotation.toJson());
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving annotation: $e')),
        );
      }
    }
  }

  void _updateStrokeWidth(double width) {
    setState(() => _currentStrokeWidth = width);
  }

  void _updateDrawingColor(Color color) {
    setState(() => _currentDrawingColor = color);
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final provider = context.read<ReportProvider>();
      final report = MedicalReport(
        id: widget.report?.id ?? '',
        title: _titleController.text,
        content: _contentController.text,
        annotations: _annotations.map((a) => Annotation.fromJson(a)).toList(),
        createdAt: widget.report?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.report == null) {
        await provider.createReport(report);
      } else {
        await provider.updateReport(report);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report == null ? 'New Report' : 'Edit Report'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReport,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isAnalyzing,
        message: 'Analyzing report...',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Report Content',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter report content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Annotations',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.color_lens),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Select Color'),
                                            content: SingleChildScrollView(
                                              child: ColorPicker(
                                                onColorChanged: (color) {
                                                  _updateDrawingColor(color);
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.line_weight),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Stroke Width'),
                                            content: Slider(
                                              value: _currentStrokeWidth,
                                              min: 1,
                                              max: 10,
                                              divisions: 9,
                                              label: _currentStrokeWidth
                                                  .toString(),
                                              onChanged: _updateStrokeWidth,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DrawingCanvas(
                              strokeColor: _currentDrawingColor,
                              strokeWidth: _currentStrokeWidth,
                              onDrawingComplete: _handleDrawingComplete,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _analyzeReport,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Analyze Report'),
                    ),
                    if (_analysis != null) ...[
                      const SizedBox(height: 24),
                      _buildAnalysisResults(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_analysis!['entities'] != null) ...[
              const Text(
                'Medical Entities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var entity in _analysis!['entities'])
                    Chip(
                      label: Text(entity['text']),
                      backgroundColor: _getEntityColor(entity['type']),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_analysis!['suggestions'] != null) ...[
              const Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (var suggestion in _analysis!['suggestions'])
                    ListTile(
                      leading: const Icon(Icons.lightbulb_outline),
                      title: Text(suggestion),
                      dense: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEntityColor(String type) {
    switch (type.toLowerCase()) {
      case 'condition':
        return Colors.red.shade100;
      case 'treatment':
        return Colors.green.shade100;
      case 'medication':
        return Colors.blue.shade100;
      case 'test':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}

class AnnotationDialog extends StatefulWidget {
  final Function(Annotation) onSave;

  const AnnotationDialog({super.key, required this.onSave});

  @override
  State<AnnotationDialog> createState() => _AnnotationDialogState();
}

class _AnnotationDialogState extends State<AnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _colorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Annotation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _xController,
                decoration: const InputDecoration(labelText: 'X'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter X coordinate';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _yController,
                decoration: const InputDecoration(labelText: 'Y'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Y coordinate';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _widthController,
                decoration: const InputDecoration(labelText: 'Width'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter width';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Height'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter height';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color (int)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a color';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final annotation = Annotation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                x: double.parse(_xController.text),
                y: double.parse(_yController.text),
                width: double.parse(_widthController.text),
                height: double.parse(_heightController.text),
                color: int.parse(_colorController.text),
              );
              widget.onSave(annotation);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
