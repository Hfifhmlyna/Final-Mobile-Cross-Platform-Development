import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';

class PdfExportService {
  /// Generate laporan presensi bulanan sebagai bytes PDF
  static Future<Uint8List> generateLaporanPresensi({
    required String kelasId,
    required String waliNama,
    required DateTime bulan,
  }) async {
    // Ambil data presensi dari Firestore
    final startOfMonth = DateTime(bulan.year, bulan.month, 1);
    final endOfMonth = DateTime(bulan.year, bulan.month + 1, 0, 23, 59, 59);
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.attendanceCol)
        .where('kelasId', isEqualTo: kelasId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('timestamp')
        .get();

    final records = snap.docs.map(AttendanceModel.fromFirestore).toList();

    // Hitung rekap per siswa
    final Map<String, Map<String, int>> rekapSiswa = {};
    final Map<String, String> namaSiswa = {};
    for (final r in records) {
      namaSiswa[r.studentId] = r.studentName;
      rekapSiswa.putIfAbsent(r.studentId, () => {'HADIR': 0, 'SAKIT': 0, 'IZIN': 0, 'ALPHA': 0});
      rekapSiswa[r.studentId]![r.status] = (rekapSiswa[r.studentId]![r.status] ?? 0) + 1;
    }

    final pdf = pw.Document();
    final periode = DateFormat('MMMM yyyy').format(bulan);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(kelasId, waliNama, periode),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('EduTech SMK', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            pw.Text('Halaman ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildRingkasan(records),
          pw.SizedBox(height: 16),
          _buildTabelRekap(rekapSiswa, namaSiswa),
          pw.SizedBox(height: 24),
          _buildTtd(waliNama, bulan),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String kelasId, String waliNama, String periode) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LAPORAN PRESENSI BULANAN',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('SMK EduTech — Sistem Manajemen Pembelajaran',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.blue800, thickness: 2),
        pw.SizedBox(height: 4),
        pw.Row(children: [
          pw.Text('Kelas: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(kelasId),
          pw.SizedBox(width: 24),
          pw.Text('Wali Kelas: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(waliNama),
          pw.SizedBox(width: 24),
          pw.Text('Periode: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(periode),
        ]),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildRingkasan(List<AttendanceModel> records) {
    final hadir = records.where((r) => r.status == 'HADIR').length;
    final alpha = records.where((r) => r.status == 'ALPHA').length;
    final sakit = records.where((r) => r.status == 'SAKIT').length;
    final izin = records.where((r) => r.status == 'IZIN').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Ringkasan Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _statBox('HADIR', hadir, PdfColors.green700),
            pw.SizedBox(width: 8),
            _statBox('ALPHA', alpha, PdfColors.red700),
            pw.SizedBox(width: 8),
            _statBox('SAKIT', sakit, PdfColors.blue700),
            pw.SizedBox(width: 8),
            _statBox('IZIN', izin, PdfColors.orange700),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _statBox(String label, int value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(
          children: [
            pw.Text('$value', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTabelRekap(
    Map<String, Map<String, int>> rekap,
    Map<String, String> namaSiswa,
  ) {
    final headers = ['No', 'Nama Siswa', 'Hadir', 'Sakit', 'Izin', 'Alpha', 'Total'];
    final rows = <List<String>>[];
    var no = 1;
    rekap.forEach((id, data) {
      final total = (data['HADIR'] ?? 0) + (data['SAKIT'] ?? 0) + (data['IZIN'] ?? 0) + (data['ALPHA'] ?? 0);
      rows.add([
        '${no++}',
        namaSiswa[id] ?? id,
        '${data['HADIR'] ?? 0}',
        '${data['SAKIT'] ?? 0}',
        '${data['IZIN'] ?? 0}',
        '${data['ALPHA'] ?? 0}',
        '$total',
      ]);
    });

    if (rows.isEmpty) {
      return pw.Text('Tidak ada data presensi pada periode ini.',
          style: const pw.TextStyle(color: PdfColors.grey));
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(36),
        5: const pw.FixedColumnWidth(40),
        6: const pw.FixedColumnWidth(40),
      },
    );
  }

  static pw.Widget _buildTtd(String waliNama, DateTime bulan) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(DateFormat('dd MMMM yyyy').format(bulan)),
            pw.SizedBox(height: 40),
            pw.Container(width: 120, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide()))),
            pw.SizedBox(height: 4),
            pw.Text(waliNama, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Wali Kelas', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }

  /// Buka / download PDF di web
  static void downloadOnWeb(Uint8List bytes, String filename) {
    if (!kIsWeb) return;
    // Web download via dart:html anchor element
    // ignore: avoid_web_libraries_in_flutter
    // Dipanggil dari UI dengan universal_html atau js interop
    debugPrint('PDF ready: $filename (${bytes.length} bytes)');
  }
}
