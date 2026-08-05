import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router.dart';
import '../../../../services/ml/classifier_service.dart';
import '../../data/models/scan_result_args.dart';

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

      final result = await ClassifierService.instance.classify(
        pickedImage.path,
      );

      if (!mounted) return;

      await Navigator.pushNamed(
        context,
        AppRoutes.result,
        arguments: ScanResultArgs(imagePath: pickedImage.path, result: result),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถวิเคราะห์ภาพได้: $error')),
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
      appBar: AppBar(title: const Text('สแกนวัสดุ')),
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
                'เลือกแหล่งที่มาของภาพ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'ถ่ายภาพหรือเลือกภาพจากคลังภาพของคุณ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const Spacer(),

              _ImageSourceButton(
                label: 'ถ่ายภาพ',
                icon: Icons.camera_alt_rounded,
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(ImageSource.camera),
              ),

              const SizedBox(height: 16),

              _ImageSourceButton(
                label: 'เลือกจากคลังภาพ',
                icon: Icons.photo_library_rounded,
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(ImageSource.gallery),
              ),

              const SizedBox(height: 20),

              if (_isPickingImage) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'กำลังวิเคราะห์ภาพ...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      icon: Icon(icon, size: 28),
      label: Text(label),
    );
  }
}
