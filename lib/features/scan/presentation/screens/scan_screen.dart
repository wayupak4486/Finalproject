import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _isPickingImage = false;

Future<void> _pickImage(ImageSource source) async {
  if (_isPickingImage) return;

  setState(() {
    _isPickingImage = true;
  });

  try {
    final XFile? pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );

    if (!mounted) return;

    if (pickedImage == null) {
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.result,
      arguments: pickedImage.path,
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot open image source: $error'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isPickingImage = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Material'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Choose Image Source',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Take a photo or select an image from your gallery.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),

              const Spacer(),

              _ImageSourceButton(
                label: 'Take Photo',
                icon: Icons.camera_alt_rounded,
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(ImageSource.camera),
              ),

              const SizedBox(height: 16),

              _ImageSourceButton(
                label: 'Select From Gallery',
                icon: Icons.photo_library_rounded,
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(ImageSource.gallery),
              ),

              const SizedBox(height: 20),

              if (_isPickingImage)
                const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
      icon: Icon(icon, size: 28),
      label: Text(label),
    );
  }
}