import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/college_comparison_result.dart';

class CompareShareService {
  Future<void> shareLink(String link) async {
    await Share.share(link, subject: 'College Reality Comparison');
  }

  Future<void> shareImage(GlobalKey repaintKey, {String? fileName}) async {
    final bytes = await _captureImage(repaintKey);
    if (bytes == null) return;
    final file = await _writeTempFile(
      bytes,
      fileName ?? 'college_comparison.png',
    );
    await Share.shareXFiles([XFile(file.path)], text: 'College comparison');
  }

  Future<void> sharePdf(CollegeComparisonResult result) async {
    final bytes = await _buildPdf(result);
    final file = await _writeTempFile(bytes, 'college_comparison.pdf');
    await Share.shareXFiles([XFile(file.path)], text: 'College comparison PDF');
  }

  Future<Uint8List?> _captureImage(GlobalKey repaintKey) async {
    final context = repaintKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<File> _writeTempFile(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List> _buildPdf(CollegeComparisonResult result) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'College Reality Comparison',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(result.summary),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: [
                'Metric',
                ...result.colleges.map((c) => c.name),
              ],
              data: result.rows
                  .map(
                    (row) => [
                      row.metric,
                      ...row.values,
                    ],
                  )
                  .toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );
    return doc.save();
  }
}
