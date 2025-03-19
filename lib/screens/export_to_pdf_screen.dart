
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:suivi_mvt_armoire_seche/models/stock_model.dart'; // Optional for showing the PDF in app

class ExportToPdfScreen extends StatelessWidget {
  final List<StockMovement> filteredMovements; // Pass the filtered movements here

  ExportToPdfScreen({super.key, required this.filteredMovements});

  Future<void> exportToPdf(BuildContext context) async {
    final pdf = pw.Document();

    // Add a page
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text(
              'Mouvements de Stock',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Produit', 'Date', 'Type Mouvement', 'Lieu', 'Opérateur', 'Quantité'],
              data: filteredMovements.map((movement) {
                return [
                  movement.productName,
                  _formatDateTime(movement.dateTime),
                  movement.movementType,
                  movement.storageLocation,
                  movement.operatorName,
                  movement.quantity.toString(),
                ];
              }).toList(),
            ),
          ],
        );
      },
    ));

    // Save the PDF
    final outputFile = await _writePdfToFile(pdf);

    // Show PDF or share it
    _showPdf(context, outputFile);
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  // Write the PDF document to a file
  Future<Uint8List> _writePdfToFile(pw.Document pdf) async {
    final pdfBytes = await pdf.save();
    return pdfBytes;
  }

  // Optionally, show the generated PDF in the app (using Flutter's pdf_viewer plugin)
  void _showPdf(BuildContext context, Uint8List pdfFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewerPage(pdfFile: pdfFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exporter en PDF"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => exportToPdf(context), // Call the export function
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => exportToPdf(context), // Trigger PDF export
          child: const Text("Exporter en PDF"),
        ),
      ),
    );
  }
}

// Optional PDF Viewer Page to view the generated PDF
class PDFViewerPage extends StatelessWidget {
  final Uint8List pdfFile;

  const PDFViewerPage({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Viewer")),
      body: Center(
        child: PDFView(
          filePath: pdfFile.toString(),
        ),
      ),
    );
  }
}
