import 'dart:io';

import 'package:flutter/material.dart';

/// Presentational widgets for [ResultScreen]. Kept separate from the
/// screen's form state and price/CO2 calculations.

class ResultCapturedImage extends StatelessWidget {
  const ResultCapturedImage({required this.imagePath, super.key});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null && File(imagePath!).existsSync();

    if (!hasImage) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: Icon(Icons.image_outlined, size: 64)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.file(
        File(imagePath!),
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class ResultInfoCard extends StatelessWidget {
  const ResultInfoCard({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ResultKeyValueRow extends StatelessWidget {
  const ResultKeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class ResultTipText extends StatelessWidget {
  const ResultTipText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
