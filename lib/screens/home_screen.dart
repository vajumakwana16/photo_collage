import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'collage_screen.dart';
import 'frame_screen.dart';
import 'full_editor_demo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 100,
                  color: Color(0xFF6750A4),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Photo Collage Demo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),
                _MenuButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Create Collage',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CollageScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.filter_frames,
                  label: 'Add Frame',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FrameScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.edit_note_rounded,
                  label: 'Full Editor Demo',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FullEditorDemo()),
                  ),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Exit',
                  isSecondary: true,
                  onTap: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSecondary ? colorScheme.secondaryContainer : colorScheme.primary,
            foregroundColor: isSecondary ? colorScheme.onSecondaryContainer : colorScheme.onPrimary,
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
