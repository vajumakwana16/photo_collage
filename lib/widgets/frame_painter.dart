import 'package:flutter/material.dart';

class DecorativeFrame extends StatelessWidget {
  final int index;
  final Widget? child;
  
  const DecorativeFrame({
    super.key, 
    required this.index,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // If index 0 (default/none), just return child or empty container
    if (index == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    return CustomPaint(
      painter: FramePainter(index: index),
      child: Container(
        // Add padding to content to not be covered by frame
        padding: const EdgeInsets.all(12), 
        // We might need to adjust padding based on frame thickness?
        // Gold: 24 px stroke -> 12 inside, 12 outside.
        // Wood: 30 px stroke -> 15 inside, 15 outside.
        // Royal: 40 px stroke -> 20 inside, 20 outside.
        // Gallery: 50 px stroke -> 25 inside, 25 outside.
        // So padding around 20-30 seems reasonable for most.
        // Let's use a safe padding or make it dynamic if we really want perfection.
        child: child,
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  final int index;
  FramePainter({required this.index});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    switch (index) {
      case 1: // Wood
        _drawWoodFrame(canvas, size, paint);
        break;
      case 2: // Modern Black
        _drawModernFrame(canvas, size, paint);
        break;
      case 3: // Royal
        _drawRoyalFrame(canvas, size, paint);
        break;
      case 4: // Soft
        _drawSoftFrame(canvas, size, paint);
        break;
      case 5: // Gallery
        _drawGalleryFrame(canvas, size, paint);
        break;
      default: // Gold (Existing)
        _drawGoldFrame(canvas, size, paint);
    }
  }

  void _drawGoldFrame(Canvas canvas, Size size, Paint paint) {
    paint.strokeWidth = 24;
    paint.color = const Color(0xFFD4AF37);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.strokeWidth = 2;
    paint.color = Colors.white.withOpacity(0.8);
    canvas.drawRect(Rect.fromLTWH(12, 12, size.width - 24, size.height - 24), paint);
    
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFA67C00);
    const oz = 30.0;
    canvas.drawRect(const Rect.fromLTWH(0, 0, oz, oz), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - oz, 0, oz, oz), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - oz, oz, oz), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - oz, size.height - oz, oz, oz), paint);
  }

  void _drawWoodFrame(Canvas canvas, Size size, Paint paint) {
    paint.strokeWidth = 30;
    paint.color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.strokeWidth = 4;
    paint.color = const Color(0xFF3E2723);
    canvas.drawRect(Rect.fromLTWH(15, 15, size.width - 30, size.height - 30), paint);
  }

  void _drawModernFrame(Canvas canvas, Size size, Paint paint) {
    paint.strokeWidth = 20;
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.strokeWidth = 1;
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(18, 18, size.width - 36, size.height - 36), paint);
  }

  void _drawRoyalFrame(Canvas canvas, Size size, Paint paint) {
    paint.strokeWidth = 40;
    paint.color = Colors.purple[900]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.color = const Color(0xFFD4AF37);
    canvas.drawCircle(const Offset(20, 20), 15, paint);
    canvas.drawCircle(Offset(size.width - 20, 20), 15, paint);
    canvas.drawCircle(Offset(20, size.height - 20), 15, paint);
    canvas.drawCircle(Offset(size.width - 20, size.height - 20), 15, paint);
  }

  void _drawSoftFrame(Canvas canvas, Size size, Paint paint) {
    paint.strokeWidth = 24;
    paint.color = Colors.pink[100]!;
    canvas.drawRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(20)), paint);

    paint.strokeWidth = 2;
    paint.color = Colors.white;
    canvas.drawRRect(RRect.fromLTRBR(12, 12, size.width - 12, size.height - 12, const Radius.circular(10)), paint);
  }

  void _drawGalleryFrame(Canvas canvas, Size size, Paint paint) {
    paint.strokeWidth = 50;
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.strokeWidth = 1;
    paint.color = Colors.grey[300]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(49, 49, size.width - 98, size.height - 98), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
