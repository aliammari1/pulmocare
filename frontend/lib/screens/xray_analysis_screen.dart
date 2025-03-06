import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../providers/xray_provider.dart';
import '../widgets/loading_overlay.dart';

class XRayAnalysisScreen extends StatefulWidget {
  const XRayAnalysisScreen({super.key});

  @override
  State<XRayAnalysisScreen> createState() => _XRayAnalysisScreenState();
}

class _XRayAnalysisScreenState extends State<XRayAnalysisScreen> {
  Uint8List? _selectedImage;
  String? _selectedFileName;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'dcm', 'dicom'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedImage = result.files.first.bytes;
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || !_formKey.currentState!.validate()) return;

    try {
      final provider = context.read<XRayProvider>();
      Map<String, dynamic> metadata = {};

      if (_notesController.text.isNotEmpty) {
        metadata['notes'] = _notesController.text;
      }

      await provider.analyzeXRay(
        _selectedImage!,
        _selectedFileName!,
        metadata: metadata,
      );

      if (mounted && provider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('X-Ray Analysis'),
        centerTitle: true,
      ),
      body: Consumer<XRayProvider>(
        builder: (context, provider, _) {
          return LoadingOverlay(
            isLoading: provider.status == AnalysisStatus.loading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagePreview(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Select X-Ray Image'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedImage != null ? _analyzeImage : null,
                      child: const Text('Analyze X-Ray'),
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (provider.currentAnalysis != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Analysis Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnalysisResults(provider.currentAnalysis!),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('No image selected'),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PhotoView(
          imageProvider: MemoryImage(_selectedImage!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisResults(Map<String, dynamic> analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis['findings'] != null) ...[
              const Text(
                'Findings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(analysis['findings'].toString()),
              const SizedBox(height: 16),
            ],
            if (analysis['recommendations'] != null) ...[
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(analysis['recommendations'].toString()),
            ],
          ],
        ),
      ),
    );
  }
}
