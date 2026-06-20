import 'dart:io';

import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfReaderView extends StatelessWidget {
  const PdfReaderView({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context) {
    final localPath = tab.localPath;
    if (localPath == null) {
      return Scaffold(
        backgroundColor: VsCodeColors.editor,
        body: Center(
          child: CircularProgressIndicator(color: VsCodeColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VsCodeColors.editor,
      body: SfPdfViewer.file(
        File(localPath),
      ),
    );
  }
}
