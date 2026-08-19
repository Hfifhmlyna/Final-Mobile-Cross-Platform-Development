import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/core/services/fcm_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

class PiketDashboardPage extends StatefulWidget {
  const PiketDashboardPage({super.key});

  @override
  State<PiketDashboardPage> createState() => _PiketDashboardPageState();
}

class _PiketDashboardPageState extends State<PiketDashboardPage>
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
        backgroundColor: AppTheme.piketColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduTech SMK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Piket: ${user?.nama ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign, color: Colors.white),
            tooltip: 'Broadcast Darurat',
            onPressed: () => _showBroadcastDialog(context, user?.uid ?? ''),
          ),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => auth.logout(context)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Quick Input'),
            Tab(icon: Icon(Icons.book), text: 'Buku Piket'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _QuickInputTab(teacherId: user?.uid),
          _BukuPiketTab(teacherId: user?.uid),
          _RiwayatTab(teacherId: user?.uid),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, String teacherId) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.campaign, color: Colors.red),
          SizedBox(width: 8),
          Text('Broadcast Darurat'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifikasi akan dikirim ke SEMUA pengguna.', style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Darurat')),
            const SizedBox(height: 8),
            TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Isi Pesan')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await FCMService().broadcastEmergency(
                title: titleCtrl.text,
                body: bodyCtrl.text,
                sentBy: teacherId,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Broadcast darurat dikirim!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Kirim Sekarang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Quick Input Presensi ─────────────────────────────────────────────────────
class _QuickInputTab extends StatefulWidget {
  final String? teacherId;
  const _QuickInputTab({this.teacherId});

  @override
  State<_QuickInputTab> createState() => _QuickInputTabState();
}

class _QuickInputTabState extends State<_QuickInputTab> {
  final _nisCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _kelasCtrl = TextEditingController();
  String _status = 'HADIR';
  bool _saving = false;
  final _statuses = ['HADIR', 'SAKIT', 'IZIN', 'ALPHA'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  Row(
                    children: [
                      const Icon(Icons.how_to_reg, color: AppTheme.piketColor),
                      const SizedBox(width: 8),
                      const Text('Input Presensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _showQRScanner(context),
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: const Text('Scan QR'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nisCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'NIS Siswa', prefixIcon: Icon(Icons.badge)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Siswa', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _kelasCtrl,
                    decoration: const InputDecoration(labelText: 'Kelas', prefixIcon: Icon(Icons.class_)),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.piketColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan Presensi', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Presensi Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.attendanceCol)
                .where('recordedBy', isEqualTo: widget.teacherId)
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada presensi')));
              return Column(
                children: docs.map((doc) {
                  final a = AttendanceModel.fromFirestore(doc);
                  final color = switch (a.status) {
                    'HADIR' => Colors.green,
                    'SAKIT' => Colors.blue,
                    'IZIN' => Colors.orange,
                    _ => Colors.red,
                  };
                  return Card(
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(backgroundColor: color, radius: 16, child: Text(a.status[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                      title: Text(a.studentName),
                      subtitle: Text('${a.kelasId} • ${DateFormat('HH:mm').format(a.timestamp)}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showQRScanner(BuildContext context) {
    if (kIsWeb) {
      // Web tidak support kamera native — tampilkan info
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Scan QR Code'),
          content: const Text('Fitur QR Scanner hanya tersedia di aplikasi Android/iOS.\nGunakan input manual NIS di kolom di atas.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _QRScannerPage(
        onScanned: (code) {
          Navigator.pop(context);
          setState(() => _nisCtrl.text = code);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR terdeteksi: $code')),
          );
        },
      )),
    );
  }

  Future<void> _save() async {
    if (_namaCtrl.text.isEmpty || _kelasCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection(AppConstants.attendanceCol).add(
        AttendanceModel(
          id: '',
          studentId: _nisCtrl.text,
          studentName: _namaCtrl.text,
          kelasId: _kelasCtrl.text,
          status: _status,
          timestamp: DateTime.now(),
          recordedBy: widget.teacherId ?? '',
        ).toMap(),
      );
      _nisCtrl.clear();
      _namaCtrl.clear();
      setState(() => _status = 'HADIR');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presensi tersimpan!')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Buku Piket ───────────────────────────────────────────────────────────────
class _BukuPiketTab extends StatefulWidget {
  final String? teacherId;
  const _BukuPiketTab({this.teacherId});

  @override
  State<_BukuPiketTab> createState() => _BukuPiketTabState();
}

class _BukuPiketTabState extends State<_BukuPiketTab> {
  final _catatanCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Buku Piket - ${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catatan Harian', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catatanCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Tulis kejadian, catatan, atau laporan piket hari ini...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : () => _saveCatatan(today),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.piketColor),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Catatan', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Catatan Sebelumnya', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.piketLogCol)
                .where('teacherId', isEqualTo: widget.teacherId)
                .orderBy('date', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada catatan')));
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.book, color: AppTheme.piketColor),
                      title: Text(d['catatan'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(d['date'] ?? ''),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveCatatan(String today) async {
    if (_catatanCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection(AppConstants.piketLogCol).add({
        'teacherId': widget.teacherId,
        'date': today,
        'catatan': _catatanCtrl.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _catatanCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan disimpan!')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Riwayat Piket ────────────────────────────────────────────────────────────
class _RiwayatTab extends StatelessWidget {
  final String? teacherId;
  const _RiwayatTab({this.teacherId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.attendanceCol)
          .where('recordedBy', isEqualTo: teacherId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Belum ada riwayat presensi'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final a = AttendanceModel.fromFirestore(docs[i]);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text('${a.studentName} (${a.kelasId})'),
                subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(a.timestamp)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.status == 'HADIR' ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(a.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: a.status == 'HADIR' ? Colors.green : Colors.red)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── QR Scanner Page (mobile only) ─────────────────────────────────────────
class _QRScannerPage extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const _QRScannerPage({required this.onScanned});

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.piketColor,
        title: const Text('Scan QR / Barcode Siswa', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _ctrl.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                setState(() => _scanned = true);
                widget.onScanned(barcode!.rawValue!);
              }
            },
          ),
          // Overlay frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.piketColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Text('Arahkan kamera ke QR Code / Barcode NIS siswa',
                    style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
