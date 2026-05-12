import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/scan_result.dart';
import '../services/ocr_service.dart';
import '../services/keyword_extractor.dart';
import '../services/recommendation_service.dart';
import '../widgets/app_header.dart';
import '../widgets/scanning_overlay.dart';
import 'scan_results_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScanState { idle, scanning, processing, error }

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  _ScanState _state = _ScanState.idle;
  String _errorMessage = '';
  String _processingStep = '';
  String? _imagePath;
  Uint8List? _imageBytes;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return;

    // Read bytes for web compatibility
    final bytes = await image.readAsBytes();

    setState(() {
      _state = _ScanState.scanning;
      _imagePath = image.path;
      _imageBytes = bytes;
    });

    // Show scanning overlay for 2 seconds
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;
    setState(() {
      _state = _ScanState.processing;
      _processingStep = 'Detecting text with AI...';
    });

    try {
      // Google ML Kit is native-only (Android/iOS) — not supported on web
      if (kIsWeb) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage =
              'OCR scanning requires a mobile device.\n'
              'Google ML Kit runs on-device AI and is not available on web.\n'
              'Please use Android or iOS to scan notes.';
        });
        return;
      }

      final rawText = await OcrService.instance.recognizeText(image.path);
      if (rawText.trim().isEmpty) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'No text detected. Try a clearer photo.';
        });
        return;
      }

      setState(() => _processingStep = 'Extracting keywords...');
      await Future.delayed(const Duration(milliseconds: 400));
      final extraction = KeywordExtractor.instance.extract(rawText);

      setState(() => _processingStep = 'Finding matching study groups...');
      await Future.delayed(const Duration(milliseconds: 400));
      final recommendations = await RecommendationService.instance.recommend(
        keywords: extraction.keywords,
        topicScores: extraction.topicScores,
      );

      if (!mounted) return;
      final scanResult = ScanResult(
        rawText: rawText,
        keywords: extraction.keywords,
        topicScores: extraction.topicScores,
      );
      setState(() {
        _state = _ScanState.idle;
        _imagePath = null;
      });

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScanResultsScreen(
              scanResult: scanResult,
              recommendations: recommendations,
            ),
          ),
        );
      }
    } on OcrException catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  void _reset() => setState(() {
        _state = _ScanState.idle;
        _errorMessage = '';
        _imagePath = null;
        _imageBytes = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (_state) {
          _ScanState.idle => _buildIdleView(),
          _ScanState.scanning => _buildScanningView(),
          _ScanState.processing => _buildProcessingView(),
          _ScanState.error => _buildErrorView(),
        },
      ),
    );
  }

  // ───────────── IDLE ─────────────
  Widget _buildIdleView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const AppHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanner', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 4),
                Text('Scan your study notes with Edge AI',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Hero icon with pulse glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = 0.15 + (_pulseController.value * 0.15);
              return Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: glow),
                      blurRadius: 30,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Scan Study Notes', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Take a photo of your notes and AI will detect topics and recommend study groups.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          // Edge AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfacePurple,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.memory_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Edge AI — All processing on device',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Camera button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
              onPressed: () => _pickAndScan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Take Photo'),
            ),
          ),
          const SizedBox(height: 12),
          // Gallery button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _pickAndScan(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              label: Text(
                'Choose from Gallery',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Tips card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text('Tips for best results',
                          style: AppTextStyles.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Ensure good lighting\n• Shoot from above, straight\n• Text must be clearly readable\n• Works with handwritten or printed text',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF92400E),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ───────────── SCANNING (with overlay) ─────────────
  Widget _buildScanningView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image preview (web-compatible)
        if (_imageBytes != null)
          Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
          )
        else if (!kIsWeb && _imagePath != null)
          Image.file(
            File(_imagePath!),
            fit: BoxFit.cover,
          )
        else
          Container(color: Colors.black),
        // Scanning overlay with corner brackets and highlight bars
        const ScanningOverlay(),
        // Top bar
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(
            children: [
              _buildCircleButton(Icons.close_rounded, _reset),
              const Spacer(),
              _buildCircleButton(Icons.bolt_rounded, null),
            ],
          ),
        ),
        // "SCANNING NOTES..." label
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.document_scanner_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'SCANNING NOTES...',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Bottom controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircleButton(Icons.photo_library_rounded, null,
                  size: 52),
              // Capture button
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.6),
                    width: 4,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                  ),
                ),
              ),
              _buildCircleButton(Icons.auto_awesome, null, size: 52),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback? onTap,
      {double size = 44}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  // ───────────── PROCESSING ─────────────
  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(_processingStep,
              style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('AI running on your device...',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // ───────────── ERROR ─────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text('Processing Failed', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(_errorMessage,
                textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
