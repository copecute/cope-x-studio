import 'dart:typed_data';

import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';

class PptxViewer extends StatelessWidget {
  const PptxViewer({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VsCodeColors.editor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: VsCodeColors.tabBar,
            child: Row(
              children: [
                const Icon(Icons.slideshow_outlined, size: 16),
                const SizedBox(width: 8),
                Text('PowerPoint Viewer — ${tab.pptxSlides.length} slide'),
                const Spacer(),
                Text(
                  'Chế độ xem (read-only)',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tab.pptxSlides.length,
              itemBuilder: (context, index) {
                final slide = tab.pptxSlides[index];
                return _SlideCard(slide: slide);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final PptxSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slide ${slide.index}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: VsCodeColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            if (slide.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    Uint8List.fromList(slide.imageBytes!),
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: VsCodeColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final text in slide.texts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
