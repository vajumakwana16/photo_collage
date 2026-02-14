import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../models/collage_provider.dart';
import '../widgets/frame_painter.dart';

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  final ScreenshotController _screenshotController = ScreenshotController(); 
  int? _selectedFreeformIndex; // Track selected image for freeform mode

  // Gesture state
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  Offset _initialOffset = Offset.zero;

  Future<void> _exportCollage(BuildContext context) async {
    final provider = context.read<CollageProvider>();
    if (provider.collageImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select images first')),
      );
      return;
    }

    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/collage_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);
        
        await Gal.putImage(imageFile.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collage saved to gallery!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving collage: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Collage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CollageProvider>().clearCollage(),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _exportCollage(context), 
          ),
        ],
      ),
      body: Consumer<CollageProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildAspectRatioSelector(provider),
              const SizedBox(height: 10),
              _buildLayoutSelector(provider),
              Expanded(
                child: Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: _buildCollageContent(provider),
                  ),
                ),
              ),
              _buildSpacingSlider(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpacingSlider(CollageProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grid Spacing', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${provider.spacing.toInt()} px'),
            ],
          ),
          Slider(
            value: provider.spacing,
            min: 0,
            max: 20,
            onChanged: (value) => provider.setSpacing(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatioSelector(CollageProvider provider) {
    final ratios = [
      {'name': '1:1', 'ratio': 1.0, 'icon': Icons.crop_square},
      {'name': '4:5', 'ratio': 0.8, 'icon': Icons.crop_portrait}, // Insta Portrait
      {'name': '16:9', 'ratio': 16/9, 'icon': Icons.crop_landscape}, // YouTube
      {'name': '9:16', 'ratio': 9/16, 'icon': Icons.crop_portrait}, // Story/TikTok
      {'name': '3:4', 'ratio': 3/4, 'icon': Icons.crop_portrait}, // FB Post
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ratios.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final ratio = ratios[index]['ratio'] as double;
          final isSelected = (provider.aspectRatio - ratio).abs() < 0.01;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => provider.setAspectRatio(ratio),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  children: [
                    Text(
                      ratios[index]['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
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




  Widget _buildLayoutSelector(CollageProvider provider) {
    final layouts = [
      {'name': 'Grid', 'icon': Icons.grid_view_rounded},
      {'name': 'Columns', 'icon': Icons.view_column_rounded},
      {'name': 'Hero', 'icon': Icons.view_quilt_rounded},
      {'name': 'Mosaic', 'icon': Icons.view_compact_rounded},
      {'name': 'Polaroid', 'icon': Icons.auto_awesome_motion_rounded},
      {'name': 'Scattered', 'icon': Icons.layers_rounded},
      {'name': 'Freeform', 'icon': Icons.gesture_rounded},
    ];



    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: layouts.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isSelected = provider.selectedLayoutIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => provider.setLayout(index),
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
                    Icon(
                      layouts[index]['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      layouts[index]['name'] as String,
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

  Widget _buildCollageContent(CollageProvider provider) {
    final images = provider.collageImages;
    return AspectRatio(
      aspectRatio: provider.aspectRatio,
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
        child: _buildLayout(provider.selectedLayoutIndex, images, provider.spacing),
      ),
    );
  }

  Widget _buildLayout(int layoutIndex, List<File> images, double spacing) {
    switch (layoutIndex) {
      case 1: // 3 Columns
        return _buildColumnLayout(images, spacing);
      case 2: // Hero Layout
        return _buildHeroLayout(images, spacing);
      case 3: // Mosaic
        return _buildMosaicLayout(images, spacing);
      case 4: // Polaroid (Requested: images with offsets)
        return _buildPolaroidLayout(images);
      case 5: // Scattered
        return _buildScatteredLayout(images);
      case 6: // Freeform (Scrapbook mode)
        return _buildFreeformCanvas(images);
      default: // Classic Grid
        return GridView.builder(
          padding: EdgeInsets.all(spacing),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: images.length > 4 ? images.length : 4,
          itemBuilder: (context, index) => _interactiveSlot(index, images),
        );
    }
  }

  Widget _buildPolaroidLayout(List<File> images) {
    return Container(
      color: const Color(0xFF1A1A1A), // Dark background for contrast
      child: Stack(
        children: [
          // Main Left Image
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 200,
            child: _polaroidSlot(0, images, rotation: 0),
          ),
          // Slanted Right Images (Like reference)
          Positioned(
            right: 10,
            top: 20,
            width: 140,
            height: 100,
            child: _polaroidSlot(1, images, rotation: -0.05),
          ),
          Positioned(
            right: 30,
            top: 130,
            width: 140,
            height: 100,
            child: _polaroidSlot(2, images, rotation: 0.08),
          ),
          Positioned(
            right: 15,
            top: 240,
            width: 140,
            height: 100,
            child: _polaroidSlot(3, images, rotation: -0.03),
          ),
        ],
      ),
    );
  }

  Widget _buildScatteredLayout(List<File> images) {
    return Container(
      color: const Color(0xFF2D2D2D),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 20,
            width: 150,
            height: 150,
            child: _polaroidSlot(0, images, rotation: -0.1),
          ),
          Positioned(
            right: 20,
            top: 40,
            width: 160,
            height: 160,
            child: _polaroidSlot(1, images, rotation: 0.15),
          ),
          Positioned(
             left: 100,
             bottom: 30,
             width: 180,
             height: 180,
             child: _polaroidSlot(2, images, rotation: -0.05),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            width: 100,
            height: 100,
            child: _polaroidSlot(3, images, rotation: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeformCanvas(List<File> images) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFreeformIndex = null),
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: const Color(0xFF121212),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(
            images.length > 4 ? images.length : 4,
            (index) => _transformableSlot(index, images),
          ),
        ),
      ),
    );
  }

  Widget _transformableSlot(int index, List<File> images) {
    return Consumer<CollageProvider>(
      builder: (context, provider, child) {
        final offset = provider.getOffset(index);
        final scale = provider.getScale(index);
        final rotation = provider.getRotation(index);
        final isSelected = _selectedFreeformIndex == index;

        return Positioned(
          left: 100 + offset.dx,
          top: 100 + offset.dy,
          width: 150 * scale,
          height: 150 * scale,
          child: Transform.rotate(
            angle: rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main Image Area
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFreeformIndex = index),
                    onScaleStart: isSelected ? (details) {
                      _initialScale = provider.getScale(index);
                      _initialRotation = provider.getRotation(index);
                      _initialOffset = provider.getOffset(index);
                    } : null,
                    onScaleUpdate: isSelected ? (details) {
                      // Apply scale
                      final newScale = (_initialScale * details.scale).clamp(0.5, 3.0);
                      
                      // Apply rotation
                      final newRotation = _initialRotation + details.rotation;

                      // Apply translation (pan)
                      provider.updateTransform(
                        index,
                        scale: newScale,
                        rotation: newRotation,
                        offset: provider.getOffset(index) + details.focalPointDelta,
                      );
                    } : null,
                    // Ensure we catch hits even if child is transparent
                    behavior: HitTestBehavior.opaque, 
                    child: Container(
                      decoration: isSelected 
                        ? BoxDecoration(
                            border: Border.all(color: Colors.blueAccent, width: 2),
                          ) 
                        : null,
                      child: _polaroidSlot(index, images, rotation: 0, isFreeform: true, isSelected: isSelected),
                    ),
                  ),
                ),
                
                if (isSelected) ...[
                  // Edit Button (Top Right) -> Kept as requested (or implicitly kept)
                  // User said "remove rotate and make it ratate using gestures... same for size"
                  // They didn't say remove Edit button explicitly but "no need frame in editing" (handled separately).
                  Positioned(
                    top: -12,
                    right: -12,
                    child: _buildControlBtn(
                      Icons.edit, 
                      onTap: () => _showEditDialog(context, index, provider),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlBtn(IconData icon, {VoidCallback? onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Icon(
          icon, 
          size: 18, 
          color: color == Colors.white ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }

  Widget _polaroidSlot(int index, List<File> images, {double rotation = 0, bool isFreeform = false, bool isSelected = false}) {
    return Consumer<CollageProvider>(
      builder: (context, provider, _) { 
        final frameIndex = provider.getFrameForImage(index);
        
        return Transform.rotate(
          angle: rotation,
          child: DecorativeFrame(
             index: frameIndex,
             child: _interactiveSlot(index, images, isFreeform: isFreeform, isSelected: isSelected),
          ),
        );
      }
    );
  }


  Widget _buildColumnLayout(List<File> images, double spacing) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(child: _interactiveSlot(0, images)),
              SizedBox(height: spacing),
              Expanded(child: _interactiveSlot(1, images)),
            ],
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _interactiveSlot(2, images)),
              SizedBox(height: spacing),
              Expanded(child: _interactiveSlot(3, images)),
            ],
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _interactiveSlot(4, images)),
              SizedBox(height: spacing),
              Expanded(child: _interactiveSlot(5, images)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroLayout(List<File> images, double spacing) {
    return Row(
      children: [
        Expanded(flex: 2, child: _interactiveSlot(0, images)),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _interactiveSlot(1, images)),
              SizedBox(height: spacing),
              Expanded(child: _interactiveSlot(2, images)),
              SizedBox(height: spacing),
              Expanded(child: _interactiveSlot(3, images)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMosaicLayout(List<File> images, double spacing) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _interactiveSlot(0, images)),
              SizedBox(width: spacing),
              Expanded(flex: 2, child: _interactiveSlot(1, images)),
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 2, child: _interactiveSlot(2, images)),
              SizedBox(width: spacing),
              Expanded(child: _interactiveSlot(3, images)),
            ],
          ),
        ),
      ],
    );
  }


  Widget _interactiveSlot(int index, List<File> images, {bool isFreeform = false, bool isSelected = false}) {
    final bool isEmpty = index >= images.length;

    if (isEmpty) {
      return InkWell(
        onTap: () => context.read<CollageProvider>().pickSingleImage(index),
        child: Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.add_photo_alternate_outlined, size: 30, color: Colors.grey),
          ),
        ),
      );
    }

    return Consumer<CollageProvider>(
      builder: (context, provider, child) {
        final content = _img(images[index], provider, index);
        
        // In Freeform mode:
        // - If SELECTED: Return raw content to allow parent gesture detector to Move/Scale/Rotate the frame.
        // - If NOT selected: Return InteractiveViewer to allow panning/zooming the INNER image.
        if (isFreeform) {
          if (isSelected) {
            return content;
          } else {
            return ClipRect(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: content,
              ),
            );
          }
        }

        // In Grid mode, allow internal panning/zooming and tap to edit.
        // Swapping (Draggable/DragTarget) is removed as requested.
        return GestureDetector(
          onTap: () => _showEditDialog(context, index, provider),
          child: ClipRect(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: content,
            ),
          ),
        );
      },
    );
  }


  void _showEditDialog(BuildContext context, int index, CollageProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Image ${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // LIVE PREVIEW
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ColorFiltered(
                  colorFilter: provider.getColorFilter(index),
                  child: Image.file(
                    provider.collageImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              _editSlider('Brightness', provider.getBrightness(index), -0.5, 0.5, (val) {
                provider.setBrightness(index, val);
                setState(() {});
              }),
              _editSlider('Contrast', provider.getContrast(index), -0.5, 0.5, (val) {
                provider.setContrast(index, val);
                setState(() {});
              }),

              const SizedBox(height: 20),
              const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Normal', null, index, provider, setState),
                    _filterChip('Vintage', 'Vintage', index, provider, setState),
                    _filterChip('Grayscale', 'Grayscale', index, provider, setState),
                    _filterChip('Sepia', 'Sepia', index, provider, setState),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Frames removed as requested
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  provider.removeImage(index);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(2)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _filterChip(String label, String? filter, int index, CollageProvider provider, StateSetter setState) {
    final isSelected = provider.getFilter(index) == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          provider.setFilter(index, filter);
          setState(() {});
        },
      ),
    );
  }



  Widget _img(File file, CollageProvider provider, int index) => 
    ColorFiltered(
      colorFilter: provider.getColorFilter(index),
      child: Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
    );
}


