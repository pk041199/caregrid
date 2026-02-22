import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IdCardScreen extends StatefulWidget {
  const IdCardScreen({
    super.key,
    required this.organizationName,
    required this.familyId,
    required this.qrValue,
    required this.members,
    required this.address,
    required this.issuedBy,
  });

  final String organizationName;
  final String familyId;
  final String qrValue;
  final List<Map<String, String>> members;
  final String address;
  final String issuedBy;

  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen> {
  double _previewScale = 1.0;

  @override
  Widget build(BuildContext context) {
    const cardRatio = 85.6 / 54.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family ID Card'),
        actions: [
          TextButton.icon(
            onPressed: () => _sharePdf(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          TextButton.icon(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
          TextButton.icon(
            onPressed: () => _printPdf(context),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('Preview Scale'),
              Expanded(
                child: Slider(
                  value: _previewScale,
                  min: 0.6,
                  max: 1.4,
                  divisions: 8,
                  label: _previewScale.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _previewScale = v),
                ),
              ),
            ],
          ),
          const Text('Front Side', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Center(
            child: Transform.scale(
              scale: _previewScale,
              child: SizedBox(
                width: 320,
                child: AspectRatio(
                  aspectRatio: cardRatio,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.organizationName.isEmpty
                                ? 'Demo Organization'
                                : widget.organizationName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Family ID: ${widget.familyId}'),
                          Text(
                            'Address: ${widget.address.isEmpty ? '-' : widget.address}',
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Members',
                            style:
                                TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          ...widget.members.map(
                            (m) => Text(
                              '${m['fullName'] ?? '-'} | '
                              'Age ${m['age'] ?? '-'} | '
                              '${m['sex'] ?? '-'}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Instructions: Keep this card safe. Use for follow-ups.',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Back Side', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Center(
            child: Transform.scale(
              scale: _previewScale,
              child: SizedBox(
                width: 320,
                child: AspectRatio(
                  aspectRatio: cardRatio,
                  child: Card(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: widget.qrValue,
                            size: 150,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.qrValue,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildPdfBytes() async {
    return _buildPdfBytesWithMode(printableA4: false);
  }

  Future<Uint8List> _buildPdfBytesWithMode({required bool printableA4}) async {
    final doc = pw.Document();
    final cardFormat = PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm);
    final cardWidth = 85.6 * PdfPageFormat.mm;
    final cardHeight = 54 * PdfPageFormat.mm;

    doc.addPage(
      pw.Page(
        pageFormat: printableA4 ? PdfPageFormat.a4 : cardFormat,
        build: (context) {
          final card = _buildFrontPage();
          if (!printableA4) return card;
          return _buildA4Carrier(
            card: card,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          );
        },
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: printableA4 ? PdfPageFormat.a4 : cardFormat,
        build: (context) {
          final card = _buildBackPage();
          if (!printableA4) return card;
          return _buildA4Carrier(
            card: card,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildA4Carrier({
    required pw.Widget card,
    required double cardWidth,
    required double cardHeight,
  }) {
    return pw.Center(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'Print at 100% scale (Actual size)',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: cardWidth,
            height: cardHeight,
            padding: const pw.EdgeInsets.all(0),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.6),
            ),
            child: card,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFrontPage() {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            widget.organizationName.isEmpty
                ? 'Demo Organization'
                : widget.organizationName,
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Family ID: ${widget.familyId}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            'Address: ${widget.address.isEmpty ? '-' : widget.address}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Family Members',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 2),
          ...widget.members.map(
            (m) => pw.Text(
              '${m['fullName'] ?? '-'} | Age ${m['age'] ?? '-'} | ${m['sex'] ?? '-'}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Spacer(),
          pw.Text(
            'Instructions: Keep this card safe. Use for follow-ups.',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBackPage() {
    return pw.Center(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: widget.qrValue,
            width: 140,
            height: 140,
          ),
          pw.SizedBox(height: 6),
          pw.Text(widget.qrValue, style: const pw.TextStyle(fontSize: 7)),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final bytes = await _buildPdfBytes();
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use the browser print dialog to save as PDF.'),
          ),
        );
      }
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'family_id_card_${widget.familyId}.pdf',
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    final bytes = await _buildPdfBytes();
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share is not supported on web. Use Download/Print.'),
          ),
        );
      }
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'family_id_card_${widget.familyId}.pdf',
    );
  }

  Future<void> _printPdf(BuildContext context) async {
    final bytes = await _buildPdfBytesWithMode(printableA4: true);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
