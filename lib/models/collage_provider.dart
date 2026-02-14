import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CollageProvider with ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  
  // Collage related state
  List<File> _collageImages = [];
  List<File> get collageImages => _collageImages;
  
  int _selectedLayoutIndex = 0;
  int get selectedLayoutIndex => _selectedLayoutIndex;

  double _spacing = 4.0;
  double get spacing => _spacing;

  double _aspectRatio = 1.0;
  double get aspectRatio => _aspectRatio;

  // Frame related state
  File? _frameImage;

  File? get frameImage => _frameImage;
  
  int _selectedFrameIndex = 0;
  // int _selectedFrameIndex = 0;
  int get selectedFrameIndex => _selectedFrameIndex;

  // Key: Image Index, Value: Frame Index (0 = none/default)
  final Map<int, int> _itemFrames = {};
  
  int getFrameForImage(int index) => _itemFrames[index] ?? 0;

  void setLayout(int index) {
    _selectedLayoutIndex = index;
    notifyListeners();
  }

  void setSpacing(double value) {
    _spacing = value;
    notifyListeners();
  }

  void setAspectRatio(double value) {
    _aspectRatio = value;
    notifyListeners();
  }

  void setFrame(int index) {
    _selectedFrameIndex = index;
    notifyListeners();
  }

  void setFrameForImage(int index, int frameIndex) {
    _itemFrames[index] = frameIndex;
    notifyListeners();
  }

  void swapImages(int oldIndex, int newIndex) {
    if (oldIndex < _collageImages.length && newIndex < _collageImages.length) {
      final temp = _collageImages[oldIndex];
      _collageImages[oldIndex] = _collageImages[newIndex];
      _collageImages[newIndex] = temp;
      notifyListeners();
    }
  }

  // Transformation State for Freeform Layout
  final Map<int, Offset> _offsets = {
    0: const Offset(-50, -50),
    1: const Offset(50, -60),
    2: const Offset(-40, 60),
    3: const Offset(60, 50),
    4: const Offset(0, 0),
    5: const Offset(20, -100),
  };
  final Map<int, double> _scales = {};
  final Map<int, double> _rotations = {};

  Offset getOffset(int index) => _offsets[index] ?? Offset.zero;

  double getScale(int index) => _scales[index] ?? 1.0;
  double getRotation(int index) => _rotations[index] ?? 0.0;

  void updateTransform(int index, {Offset? offset, double? scale, double? rotation}) {
    if (offset != null) _offsets[index] = offset;
    if (scale != null) _scales[index] = scale;
    if (rotation != null) _rotations[index] = rotation;
    notifyListeners();
  }

  void resetTransforms() {
    _offsets.clear();
    _scales.clear();
    _rotations.clear();
    notifyListeners();
  }

  // Image Editing State
  final Map<int, double> _brightness = {};
  final Map<int, double> _contrast = {};
  final Map<int, double> _saturation = {};
  final Map<int, String?> _activeFilters = {};

  double getBrightness(int index) => _brightness[index] ?? 0.0;
  double getContrast(int index) => _contrast[index] ?? 0.0;
  double getSaturation(int index) => _saturation[index] ?? 0.0;
  String? getFilter(int index) => _activeFilters[index];

  void setBrightness(int index, double value) {
    _brightness[index] = value;
    notifyListeners();
  }

  void setContrast(int index, double value) {
    _contrast[index] = value;
    notifyListeners();
  }

  void setSaturation(int index, double value) {
    _saturation[index] = value;
    notifyListeners();
  }

  void setFilter(int index, String? filter) {
    _activeFilters[index] = filter;
    notifyListeners();
  }

  ColorFilter getColorFilter(int index) {
    final b = getBrightness(index); // -1.0 to 1.0 (we use -0.5 to 0.5)
    final c = getContrast(index) + 1.0; // 0.5 to 1.5
    final filter = getFilter(index);

    // Initial matrix (Identity)
    List<double> matrix = [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // Brightness (Simplified)
    matrix[4] += b * 255;
    matrix[9] += b * 255;
    matrix[14] += b * 255;

    // Contrast (Base)
    double invC = 1.0 - c;
    double t = 128.0 * invC;
    matrix[0] *= c;
    matrix[5] *= c;
    matrix[10] *= c;
    matrix[4] += t;
    matrix[9] += t;
    matrix[14] += t;
    
    // Minimal filter logic
    if (filter == 'Vintage') {
       // Warm yellowish tint
       matrix[10] *= 0.8; // Reduce blue
       matrix[0] *= 1.2;  // Increase red
    } else if (filter == 'Grayscale') {
       return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
       ]);
    } else if (filter == 'Sepia') {
       return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
       ]);
    }

    return ColorFilter.matrix(matrix);
  }

  void removeImage(int index) {
    if (index < _collageImages.length) {
      _collageImages.removeAt(index);
      // Clear its specific edits
      _brightness.remove(index);
      _contrast.remove(index);
      _saturation.remove(index);
      _saturation.remove(index);
      _activeFilters.remove(index);
      _itemFrames.remove(index);
      notifyListeners();
    }
  }

  Future<void> pickSingleImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      if (index < _collageImages.length) {
        _collageImages[index] = file;
      } else {
        // If it's a new slot, just add it
        _collageImages.add(file);
      }
      notifyListeners();
    }
  }

  Future<void> pickCollageImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      // Allow up to 6 images for more complex layouts
      _collageImages = images.take(6).map((image) => File(image.path)).toList();
      notifyListeners();
    }
  }

  Future<void> pickFrameImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _frameImage = File(image.path);
      notifyListeners();
    }
  }

  void clearCollage() {
    _collageImages = [];
    _selectedLayoutIndex = 0;
    _itemFrames.clear();
    notifyListeners();
  }

  void clearFrame() {
    _frameImage = null;
    _selectedFrameIndex = 0;
    notifyListeners();
  }
}

