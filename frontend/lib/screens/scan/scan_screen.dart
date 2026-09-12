import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../result/result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State createState() => _ScanScreenState();
}

class _ScanScreenState extends State {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Bytes are used for preview (works everywhere: web, Android, iOS).
  // The XFile is kept for its real file path, which the on-device OCR
  // (ML Kit) needs — it can't work from bytes alone.
  XFile? _pickedFile;
  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;

  Future _captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90, // keep reasonably high res for OCR accuracy
    );
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _pickedFile = photo;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future _submitForScanning() async {
    if (_selectedImageBytes == null) return;
    setState(() => _isProcessing = true);

    try {
      final result = await _apiService.submitScan(
        _selectedImageBytes!,
        imagePath: kIsWeb ? null : _pickedFile?.path,
        fileName: _pickedFile?.name ?? 'label.jpg',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(scanResult: result)),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Scan failed'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _retake() {
    setState(() {
      _pickedFile = null;
      _selectedImageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Product Label')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _selectedImageBytes == null
                  ? _buildEmptyState()
                  : _buildPreview(),
            ),
            const SizedBox(height: 16),
            if (_selectedImageBytes == null) _buildCaptureButtons(),
            if (_selectedImageBytes != null) _buildSubmitButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Capture or upload a clear photo of the\nproduct label / principal display panel',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.contain,
        width: double.infinity,
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _captureFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Upload'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _retake,
            child: const Text('Retake'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _submitForScanning,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Check Compliance'),
          ),
        ),
      ],
    );
  }
}