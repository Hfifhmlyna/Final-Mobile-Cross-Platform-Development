import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/core/services/pdf_export_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

class WaliDashboardPage extends StatefulWidget {
  const WaliDashboardPage({super.key});

  @override
  State<WaliDashboardPage> createState() => _WaliDashboardPageState();
}

class _WaliDashboardPageState extends State<WaliDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.waliColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduTech SMK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Wali Kelas: ${user?.nama ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => auth.logout(context)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Rekap Bulanan'),
            Tab(icon: Icon(Icons.warning), text: 'Alert'),
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RekapBulananTab(kelasId: user?.kelasId),
          _AlertTab(kelasId: user?.kelasId),
          _LaporanTab(kelasId: user?.kelasId, waliNama: user?.nama ?? ''),
        ],
      ),
    );
  }
}

// ── Rekap Bulanan ───────────────────────────────────────────────────────────
class _RekapBulananTab extends StatelessWidget {
  final String? kelasId;
  const _RekapBulananTab({this.kelasId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.attendanceCol)
          .where('kelasId', isEqualTo: kelasId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final hadir = docs.where((d) => (d.data() as Map)['status'] == 'HADIR').length;
        final alpha = docs.where((d) => (d.data() as Map)['status'] == 'ALPHA').length;
        final sakit = docs.where((d) => (d.data() as Map)['status'] == 'SAKIT').length;
        final izin = docs.where((d) => (d.data() as Map)['status'] == 'IZIN').length;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Rekap ${DateFormat('MMMM yyyy').format(now)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Row(children: [
                _StatCard('Hadir', hadir, Colors.green),
                const SizedBox(width: 8),
                _StatCard('Alpha', alpha, Colors.red),
                const SizedBox(width: 8),
                _StatCard('Sakit', sakit, Colors.blue),
                const SizedBox(width: 8),
                _StatCard('Izin', izin, Colors.orange),
              ]),
              const SizedBox(height: 16),
              const Text('Detail Presensi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('Belum ada data presensi bulan ini'))
                    : ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final a = AttendanceModel.fromFirestore(docs[i]);
                          return ListTile(
                            dense: true,
                            title: Text(a.studentName),
                            subtitle: Text(DateFormat('dd MMM').format(a.timestamp)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: a.status == 'HADIR' ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(a.status, style: TextStyle(color: a.status == 'HADIR' ? Colors.green : Colors.red, fontSize: 11)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert System ────────────────────────────────────────────────────────────
class _AlertTab extends StatefulWidget {
  final String? kelasId;
  const _AlertTab({this.kelasId});

  @override
  State<_AlertTab> createState() => _AlertTabState();
}

class _AlertTabState extends State<_AlertTab> with SingleTickerProviderStateMixin {
  late TabController _subTab;

  @override
  void initState() {
    super.initState();
    _subTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTab,
          labelColor: AppTheme.waliColor,
          indicatorColor: AppTheme.waliColor,
          tabs: const [
            Tab(text: 'Alpha ≥ 3x'),
            Tab(text: 'Nilai Drop >20%'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTab,
            children: [
              _AlphaAlertView(kelasId: widget.kelasId),
              _NilaiDropAlertView(kelasId: widget.kelasId),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlphaAlertView extends StatelessWidget {
  final String? kelasId;
  const _AlphaAlertView({this.kelasId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.attendanceCol)
          .where('kelasId', isEqualTo: kelasId)
          .where('status', isEqualTo: 'ALPHA')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final Map<String, int> alphaCount = {};
        final Map<String, String> alphaNames = {};
        for (final doc in docs) {
          final a = AttendanceModel.fromFirestore(doc);
          alphaCount[a.studentId] = (alphaCount[a.studentId] ?? 0) + 1;
          alphaNames[a.studentId] = a.studentName;
        }
        final alerts = alphaCount.entries
            .where((e) => e.value >= AppConstants.alphaAlertThreshold)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _AlertBanner('Alert aktif jika Alpha ≥ ${AppConstants.alphaAlertThreshold}x', Colors.red),
              const SizedBox(height: 12),
              Expanded(
                child: alerts.isEmpty
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 12),
                        Text('Tidak ada siswa dengan alert Alpha'),
                      ]))
                    : ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (context, i) {
                          final e = alerts[i];
                          return Card(
                            color: Colors.red.withOpacity(0.05),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.person_off, color: Colors.white)),
                              title: Text(alphaNames[e.key] ?? e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Alpha: ${e.value}x'),
                              trailing: const Icon(Icons.warning, color: Colors.red),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NilaiDropAlertView extends StatelessWidget {
  final String? kelasId;
  const _NilaiDropAlertView({this.kelasId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grades')
          .where('kelasId', isEqualTo: kelasId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        // Kelompokkan nilai per siswa per mapel — deteksi nilai terbaru vs sebelumnya
        final Map<String, Map<String, List<double>>> nilaiPerSiswa = {};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final sid = d['studentId'] as String? ?? '';
          final mapel = d['mapel'] as String? ?? '';
          final nilai = (d['nilai'] as num?)?.toDouble() ?? 0;
          nilaiPerSiswa.putIfAbsent(sid, () => {})[mapel] =
              [...(nilaiPerSiswa[sid]?[mapel] ?? []), nilai];
        }

        // Cari siswa dengan nilai drop > threshold
        final List<Map<String, dynamic>> drops = [];
        nilaiPerSiswa.forEach((sid, mapelData) {
          mapelData.forEach((mapel, nilaiList) {
            if (nilaiList.length >= 2) {
              final terbaru = nilaiList.last;
              final sebelumnya = nilaiList[nilaiList.length - 2];
              final drop = sebelumnya - terbaru;
              if (drop >= AppConstants.gradeDropThreshold) {
                drops.add({
                  'studentId': sid,
                  'mapel': mapel,
                  'before': sebelumnya,
                  'after': terbaru,
                  'drop': drop,
                });
              }
            }
          });
        });

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _AlertBanner('Alert aktif jika nilai drop ≥ ${AppConstants.gradeDropThreshold.toInt()} poin', Colors.orange),
              const SizedBox(height: 12),
              Expanded(
                child: drops.isEmpty
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.trending_up, size: 64, color: Colors.green),
                        SizedBox(height: 12),
                        Text('Tidak ada penurunan nilai signifikan'),
                      ]))
                    : ListView.builder(
                        itemCount: drops.length,
                        itemBuilder: (context, i) {
                          final d = drops[i];
                          return Card(
                            color: Colors.orange.withOpacity(0.05),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.trending_down, color: Colors.white)),
                              title: Text(d['studentId'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${d['mapel']}: ${d['before']} → ${d['after']}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                child: Text('-${d['drop'].toStringAsFixed(0)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String text;
  final Color color;
  const _AlertBanner(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.warning, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: color))),
      ]),
    );
  }
}

// ── Export Laporan PDF ──────────────────────────────────────────────────────
class _LaporanTab extends StatefulWidget {
  final String? kelasId;
  final String waliNama;
  const _LaporanTab({this.kelasId, required this.waliNama});

  @override
  State<_LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<_LaporanTab> {
  bool _generating = false;
  DateTime _selectedBulan = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Kelas', widget.kelasId ?? '-'),
                  _buildInfoRow('Wali Kelas', widget.waliNama),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickBulan,
                    icon: const Icon(Icons.calendar_month),
                    label: Text('Periode: ${DateFormat('MMMM yyyy').format(_selectedBulan)}'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: (_generating || widget.kelasId == null) ? null : _exportPdf,
                    icon: _generating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: Text(_generating ? 'Membuat PDF...' : 'Export Laporan PDF',
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.waliColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Rekap Presensi (.xlsx)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(': $value', style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
      );

  Future<void> _pickBulan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBulan,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Pilih Bulan Laporan',
    );
    if (picked != null) setState(() => _selectedBulan = DateTime(picked.year, picked.month));
  }

  Future<void> _exportPdf() async {
    setState(() => _generating = true);
    try {
      final bytes = await PdfExportService.generateLaporanPresensi(
        kelasId: widget.kelasId!,
        waliNama: widget.waliNama,
        bulan: _selectedBulan,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF siap (${(bytes.length / 1024).toStringAsFixed(1)} KB)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

