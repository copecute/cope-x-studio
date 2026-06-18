import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cope_x_studio/models/editor_tab.dart';

class PdfReaderView extends StatelessWidget {
  const PdfReaderView({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context) {
    final localPath = tab.localPath;
    if (localPath == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SfPdfViewer.file(
        File(localPath),
      ),
    );
  }
}
