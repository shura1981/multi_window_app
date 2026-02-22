import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrintService {
  /// Generates a PDF document containing the user table.
  static Future<Uint8List> generateUsersPdf(List<Map<String, dynamic>> users) async {
    final pdf = pw.Document(
      title: 'Users List',
      creator: 'User Manager App',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('User Manager - Registered Users', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          if (users.isEmpty)
            pw.Text('No users registered.')
          else
            pw.Table.fromTextArray(
              context: context,
              headers: ['ID', 'Name', 'D.O.B', 'Phone'],
              data: users.map((u) => [
                u['id'].toString(),
                u['name'].toString(),
                u['dob'].toString(),
                u['phone'].toString(),
              ]).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page \${context.pageNumber} of \${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
          ),
        ),
      ),
    );

    return pdf.save();
  }
}
