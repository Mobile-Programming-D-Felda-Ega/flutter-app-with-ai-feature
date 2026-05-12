import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR service using Google ML Kit Text Recognition.
///
/// This is the core Edge AI component. The ML Kit text recognizer:
/// - Downloads a ~2.5MB neural network model to the device
/// - Runs CNN + LSTM inference entirely on-device
/// - Requires NO internet connection for text recognition
/// - Supports printed and handwritten text (Latin script)
class OcrService {
  OcrService._();
  static final instance = OcrService._();

  /// Recognize text from an image file path.
  ///
  /// Returns the extracted text string. The ML Kit model runs entirely
  /// on the device's CPU/GPU — no cloud calls are made.
  Future<String> recognizeText(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw OcrException('File gambar tidak ditemukan: $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw OcrException('Gagal memproses gambar: ${e.toString()}');
    } finally {
      await textRecognizer.close();
    }
  }
}

/// Exception thrown when OCR processing fails.
class OcrException implements Exception {
  OcrException(this.message);
  final String message;

  @override
  String toString() => 'OcrException: $message';
}
