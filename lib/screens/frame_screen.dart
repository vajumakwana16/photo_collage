import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../models/collage_provider.dart';

class FrameScreen extends StatefulWidget {
  const FrameScreen({super.key});

  @override
  State<FrameScreen> createState() => _FrameScreenState();
}

class _FrameScreenState extends State<FrameScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _exportFrame(BuildContext context) async {
    final provider = context.read<CollageProvider>();
    if (provider.frameImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/framed_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);
        
        await Gal.putImage(imageFile.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Framed image saved to gallery!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Frame'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CollageProvider>().clearFrame(),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _exportFrame(context),
          ),
        ],
      ),
      body: Consumer<CollageProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              const SizedBox(height: 10),
              _buildFrameSelector(provider),
              Expanded(
                child: Center(
                  child: provider.frameImage == null
                      ? _buildEmptyState(context)
                      : Screenshot(
                          controller: _screenshotController,
                          child: _buildFramedImage(provider),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  onPressed: () => provider.pickFrameImage(),
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Pick Image'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFrameSelector(CollageProvider provider) {
    final frames = [
      {'name': 'Gold', 'color': const Color(0xFFD4AF37)},
      {'name': 'Wood', 'color': const Color(0xFF5D4037)},
      {'name': 'Modern', 'color': Colors.black},
      {'name': 'Royal', 'color': Colors.purple},
      {'name': 'Soft', 'color': Colors.pink[200]!},
      {'name': 'Gallery', 'color': Colors.grey[300]!},
    ];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: frames.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isSelected = provider.selectedFrameIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => provider.setFrame(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: frames[index]['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      frames[index]['name'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.filter_frames_rounded,
          size: 80,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        const SizedBox(height: 16),
        const Text(
          'No image selected',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFramedImage(CollageProvider provider) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.1,
                maxScale: 4.0,
                child: Image.file(
                  provider.frameImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IgnorePointer(
              child: _DecorativeFrame(index: provider.selectedFrameIndex),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeFrame extends StatelessWidget {
  final int index;
  const _DecorativeFrame({required this.index});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: FramePainter(index: index),
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


