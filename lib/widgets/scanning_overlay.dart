import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Animated scanning overlay with corner brackets and highlight lines.
/// Creates the futuristic OCR scanning effect from the Stitch design.
class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({super.key});

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scanLineController;
  late final AnimationController _highlightController;
  late final Animation<double> _scanLineAnimation;
  late final Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _highlightAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scanW = w * 0.8;
        final scanH = h * 0.55;
        final left = (w - scanW) / 2;
        final top = (h - scanH) / 2.5;

        return Stack(
          children: [
            // Dimmed surrounding area
            _buildDimOverlay(w, h, left, top, scanW, scanH),
            // Corner brackets
            _buildCornerBrackets(left, top, scanW, scanH),
            // Animated highlight bars (text detection)
            AnimatedBuilder(
              animation: _highlightAnimation,
              builder: (context, _) {
                return _buildHighlightBars(left, top, scanW, scanH);
              },
            ),
            // Scanning line
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, _) {
                final lineY = top + (_scanLineAnimation.value * scanH);
                return Positioned(
                  left: left,
                  top: lineY,
                  child: Container(
                    width: scanW,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0),
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDimOverlay(
      double w, double h, double left, double top, double scanW, double scanH) {
    return CustomPaint(
      size: Size(w, h),
      painter: _DimPainter(
        scanRect: Rect.fromLTWH(left, top, scanW, scanH),
      ),
    );
  }

  Widget _buildCornerBrackets(
      double left, double top, double scanW, double scanH) {
    const size = 28.0;
    const strokeWidth = 3.0;
    const color = AppColors.primary;

    return Stack(
      children: [
        // Top-left
        Positioned(
          left: left, top: top,
          child: CustomPaint(
            size: const Size(size, size),
            painter: _CornerPainter(corner: _Corner.topLeft, color: color, strokeWidth: strokeWidth),
          ),
        ),
        // Top-right
        Positioned(
          left: left + scanW - size, top: top,
          child: CustomPaint(
            size: const Size(size, size),
            painter: _CornerPainter(corner: _Corner.topRight, color: color, strokeWidth: strokeWidth),
          ),
        ),
        // Bottom-left
        Positioned(
          left: left, top: top + scanH - size,
          child: CustomPaint(
            size: const Size(size, size),
            painter: _CornerPainter(corner: _Corner.bottomLeft, color: color, strokeWidth: strokeWidth),
          ),
        ),
        // Bottom-right
        Positioned(
          left: left + scanW - size, top: top + scanH - size,
          child: CustomPaint(
            size: const Size(size, size),
            painter: _CornerPainter(corner: _Corner.bottomRight, color: color, strokeWidth: strokeWidth),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightBars(
      double left, double top, double scanW, double scanH) {
    final alpha = _highlightAnimation.value;
    final barColor = AppColors.primaryLight.withValues(alpha: alpha * 0.4);
    final barH = 14.0;
    final padX = scanW * 0.12;

    // Simulate detected text lines at various positions
    final linePositions = [0.18, 0.28, 0.36, 0.44, 0.60, 0.70];
    final lineWidths = [0.55, 0.72, 0.48, 0.62, 0.50, 0.68];

    return Stack(
      children: List.generate(linePositions.length, (i) {
        return Positioned(
          left: left + padX,
          top: top + (linePositions[i] * scanH),
          child: Container(
            width: scanW * lineWidths[i],
            height: barH,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.corner,
    required this.color,
    required this.strokeWidth,
  });

  final _Corner corner;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
      case _Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
      case _Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
      case _Corner.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.corner != corner || old.color != color;
}

class _DimPainter extends CustomPainter {
  _DimPainter({required this.scanRect});
  final Rect scanRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(4))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DimPainter old) => old.scanRect != scanRect;
}
