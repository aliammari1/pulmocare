import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VisitCardScanView extends StatefulWidget {
  @override
  _VisitCardScanViewState createState() => _VisitCardScanViewState();
}

class _VisitCardScanViewState extends State<VisitCardScanView> {
  File? _image;
  Map<String, dynamic> _extractedData = {};
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _errorMessage = '';
        _extractedData = {};
      } else {
        _errorMessage = 'No image selected.';
      }
    });
  }

  Future<void> _getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _errorMessage = '';
        _extractedData = {};
      } else {
        _errorMessage = 'No image selected.';
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      setState(() => _errorMessage = 'Please select an image first.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String base64Image = base64Encode(_image!.readAsBytesSync());
      var response = await http.post(
        Uri.parse(
            'http://10.0.2.2:4000/api/scan-visit-card'), // Use your API endpoint
        headers: {"Content-Type": "application/json"},
        body: json.encode({'image': base64Image}),
      );

      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _extractedData = data;
        });
        // Optionally, return the data to the signup view
        Navigator.pop(context, _extractedData);
      } else {
        setState(() =>
            _errorMessage = data['error'] ?? 'Failed to scan visit card.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Visit Card')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _getImage,
              child: Text('Take a Picture'),
            ),
            ElevatedButton(
              onPressed: _getImageFromGallery,
              child: Text('Choose from Gallery'),
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Image.file(
                  _image!,
                  height: 200,
                ),
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadImage,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Process Image'),
                ),
              ),
            if (_extractedData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Extracted Data:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Name: ${_extractedData['name'] ?? 'N/A'}'),
                    Text('Specialty: ${_extractedData['specialty'] ?? 'N/A'}'),
                    Text('Email: ${_extractedData['email'] ?? 'N/A'}'),
                    Text(
                        'Phone Number: ${_extractedData['phone_number'] ?? 'N/A'}'),
                    Text('Address: ${_extractedData['address'] ?? 'N/A'}'),
                    // Display other extracted fields here
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
