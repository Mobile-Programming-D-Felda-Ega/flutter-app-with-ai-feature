import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/scan_result.dart';
import '../services/ocr_service.dart';
import '../services/keyword_extractor.dart';
import '../services/recommendation_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScanState { idle, processing, done, error }

class _ScannerScreenState extends State<ScannerScreen> {
  _ScanState _state = _ScanState.idle;
  ScanResult? _scanResult;
  List<GroupRecommendation> _recommendations = [];
  String _errorMessage = '';
  String _processingStep = '';
  bool _showFullText = false;

  static const _purple = Color(0xFF7C3AED);
  static const _cyan = Color(0xFF06B6D4);

  Future<void> _pickAndScan(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _state = _ScanState.processing;
      _processingStep = 'Mendeteksi teks dengan AI...';
      _scanResult = null;
      _recommendations = [];
    });

    try {
      // Step 1: OCR (on-device ML Kit)
      final rawText = await OcrService.instance.recognizeText(image.path);

      if (rawText.trim().isEmpty) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage =
              'Tidak ada teks yang terdeteksi. Coba foto yang lebih jelas.';
        });
        return;
      }

      setState(() => _processingStep = 'Mengekstrak kata kunci...');
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 2: Keyword extraction (on-device Dart logic)
      final extraction = KeywordExtractor.instance.extract(rawText);

      setState(() => _processingStep = 'Mencari study group yang cocok...');
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 3: Recommendation (on-device scoring)
      final recommendations = await RecommendationService.instance.recommend(
        keywords: extraction.keywords,
        topicScores: extraction.topicScores,
      );

      if (!mounted) return;

      setState(() {
        _scanResult = ScanResult(
          rawText: rawText,
          keywords: extraction.keywords,
          topicScores: extraction.topicScores,
        );
        _recommendations = recommendations;
        _state = _ScanState.done;
      });
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
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _scanResult = null;
      _recommendations = [];
      _errorMessage = '';
      _showFullText = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ScanState.idle => _buildIdleView(),
      _ScanState.processing => _buildProcessingView(),
      _ScanState.done => _buildResultsView(),
      _ScanState.error => _buildErrorView(),
    };
  }

  // ─── IDLE STATE ───
  Widget _buildIdleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Hero illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_purple, _cyan]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Catatan Belajar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Foto catatan kuliah dan AI akan mendeteksi topik serta merekomendasikan study group yang relevan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Edge AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _purple.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.memory_rounded, size: 16, color: _purple),
                SizedBox(width: 6),
                Text(
                  'Edge AI — Semua proses di perangkat',
                  style: TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Camera button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _pickAndScan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Ambil Foto', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Gallery button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickAndScan(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text(
                'Pilih dari Galeri',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: _purple, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tips untuk hasil terbaik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Pastikan cahaya cukup terang\n• Foto dari atas, lurus, tidak miring\n• Teks harus terbaca jelas\n• Bisa foto tulisan tangan atau cetak',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROCESSING STATE ───
  Widget _buildProcessingView() {
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
                gradient: const LinearGradient(colors: [_purple, _cyan]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: _purple),
            const SizedBox(height: 24),
            Text(
              _processingStep,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI berjalan di perangkat Anda...',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RESULTS STATE ───
  Widget _buildResultsView() {
    final result = _scanResult!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Scan Selesai!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Scan Lagi'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Extracted text card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.text_fields_rounded,
                      color: _purple,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Teks Terdeteksi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${result.rawText.split(RegExp(r'\\s+')).length} kata diekstrak',
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      _showFullText ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () =>
                        setState(() => _showFullText = !_showFullText),
                  ),
                ),
                if (_showFullText)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        result.rawText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Detected keywords
          if (result.hasKeywords) ...[
            const Row(
              children: [
                Icon(Icons.key_rounded, size: 18, color: _purple),
                SizedBox(width: 6),
                Text(
                  'Kata Kunci Terdeteksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.keywords
                  .map(
                    (k) => Chip(
                      label: Text(
                        k,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: _purple.withValues(alpha: 0.1),
                      side: BorderSide(color: _purple.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Topic scores
          if (result.topicScores.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: _purple),
                SizedBox(width: 6),
                Text(
                  'Topik Terdeteksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildTopicBars(result.topicScores),
            const SizedBox(height: 16),
          ],

          // Recommendations
          const Row(
            children: [
              Icon(Icons.group_rounded, size: 20, color: _purple),
              SizedBox(width: 6),
              Text(
                'Rekomendasi Study Group',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _recommendations.isEmpty
                ? 'Tidak ada group yang cocok dengan topik ini.'
                : '${_recommendations.length} group ditemukan berdasarkan catatan Anda:',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),

          if (_recommendations.isEmpty)
            _buildNoMatchCard()
          else
            ..._recommendations.map(_buildRecommendationCard),
        ],
      ),
    );
  }

  List<Widget> _buildTopicBars(Map<String, double> topicScores) {
    final sorted = topicScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((entry) {
      final percentage = (entry.value * 100).round();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: entry.value,
                backgroundColor: Colors.grey[200],
                color: _purple,
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRecommendationCard(GroupRecommendation rec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Score badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        rec.score >= 70
                            ? const Color(0xFF10B981)
                            : rec.score >= 40
                            ? const Color(0xFFF59E0B)
                            : Colors.grey,
                        rec.score >= 70
                            ? const Color(0xFF059669)
                            : rec.score >= 40
                            ? const Color(0xFFD97706)
                            : Colors.grey[600]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${rec.score}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.group.subjectName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec.group.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Match reasons
            ...rec.matchReasons
                .take(3)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            // Info row
            Row(
              children: [
                Icon(Icons.people_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${rec.group.memberIds.length} anggota',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rec.group.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada group yang cocok',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Buat study group baru atau tambahkan tags pada group yang ada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ERROR STATE ───
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memproses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: _purple),
            ),
          ],
        ),
      ),
    );
  }
}
