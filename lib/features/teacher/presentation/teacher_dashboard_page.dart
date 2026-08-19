import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/data/repositories.dart';
import 'package:edutech_smk/core/models/models.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';
import 'package:edutech_smk/features/shared/quiz_pages.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        backgroundColor: AppTheme.guruColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduTech SMK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Guru: ${user?.nama ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
            Tab(icon: Icon(Icons.upload_file), text: 'Materi'),
            Tab(icon: Icon(Icons.assignment_add), text: 'Tugas'),
            Tab(icon: Icon(Icons.quiz), text: 'Kuis'),
            Tab(icon: Icon(Icons.how_to_reg), text: 'Presensi'),
            Tab(icon: Icon(Icons.grade), text: 'Nilai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UploadMateriTab(teacherId: user?.uid, kelasId: user?.kelasId),
          _BuatTugasTab(teacherId: user?.uid, kelasId: user?.kelasId),
          _QuizTab(teacherId: user?.uid ?? '', kelasId: user?.kelasId ?? ''),
          _PresensiTab(teacherId: user?.uid, kelasId: user?.kelasId),
          _NilaiTab(teacherId: user?.uid, kelasId: user?.kelasId),
        ],
      ),
    );
  }
}

// ── Upload Materi ───────────────────────────────────────────────────────────
class _UploadMateriTab extends StatelessWidget {
  final String? teacherId;
  final String? kelasId;
  const _UploadMateriTab({this.teacherId, this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showUploadDialog(context),
            icon: const Icon(Icons.upload, color: Colors.white),
            label: const Text('Upload Materi Baru', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruColor, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          const Text('Materi yang Sudah Diupload', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.assignmentsCol)
                  .where('teacherId', isEqualTo: teacherId)
                  .snapshots(),
              builder: (context, snap) {
                final docs = [...?snap.data?.docs];
                docs.sort((a, b) {
                  final ta = (a.data() as Map)['createdAt'];
                  final tb = (b.data() as Map)['createdAt'];
                  if (ta == null || tb == null) return 0;
                  return (tb as Timestamp).compareTo(ta as Timestamp);
                });
                if (docs.isEmpty) return const Center(child: Text('Belum ada materi'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final a = AssignmentModel.fromFirestore(docs[i]);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: AppTheme.guruColor),
                        title: Text(a.title),
                        subtitle: Text('${a.mapel} • ${DateFormat('dd MMM').format(a.createdAt)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => FirebaseFirestore.instance
                              .collection(AppConstants.assignmentsCol)
                              .doc(a.id)
                              .delete(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final mapelCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload Materi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Materi')),
              const SizedBox(height: 8),
              TextField(controller: mapelCtrl, decoration: const InputDecoration(labelText: 'Mata Pelajaran')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection(AppConstants.assignmentsCol).add(AssignmentModel(
                id: '',
                title: titleCtrl.text,
                description: descCtrl.text,
                teacherId: teacherId ?? '',
                kelasId: kelasId ?? '',
                mapel: mapelCtrl.text,
                dueDate: DateTime.now().add(const Duration(days: 7)),
                createdAt: DateTime.now(),
              ).toMap());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ── Buat Tugas ──────────────────────────────────────────────────────────────
class _BuatTugasTab extends StatelessWidget {
  final String? teacherId;
  final String? kelasId;
  const _BuatTugasTab({this.teacherId, this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showBuatTugasDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Buat Tugas Baru', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruColor, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          const Text('Daftar Tugas Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.assignmentsCol)
                  .where('teacherId', isEqualTo: teacherId)
                  .where('dueDate', isGreaterThan: Timestamp.now())
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Tidak ada tugas aktif'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final a = AssignmentModel.fromFirestore(docs[i]);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment, color: AppTheme.guruColor),
                        title: Text(a.title),
                        subtitle: Text('Deadline: ${DateFormat('dd MMM yyyy').format(a.dueDate)}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBuatTugasDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final mapelCtrl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buat Tugas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas')),
              const SizedBox(height: 8),
              TextField(controller: mapelCtrl, decoration: const InputDecoration(labelText: 'Mata Pelajaran')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Instruksi')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection(AppConstants.assignmentsCol).add(AssignmentModel(
                id: '',
                title: titleCtrl.text,
                description: descCtrl.text,
                teacherId: teacherId ?? '',
                kelasId: kelasId ?? '',
                mapel: mapelCtrl.text,
                dueDate: deadline,
                createdAt: DateTime.now(),
              ).toMap());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ── Input Presensi Real-time ────────────────────────────────────────────────
class _PresensiTab extends StatefulWidget {
  final String? teacherId;
  final String? kelasId;
  const _PresensiTab({this.teacherId, this.kelasId});

  @override
  State<_PresensiTab> createState() => _PresensiTabState();
}

class _PresensiTabState extends State<_PresensiTab> {
  final _nisCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  String _selectedStatus = 'HADIR';
  bool _saving = false;

  final statuses = ['HADIR', 'SAKIT', 'IZIN', 'ALPHA'];

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
                  const Text('Input Presensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(controller: _nisCtrl, decoration: const InputDecoration(labelText: 'NIS Siswa', prefixIcon: Icon(Icons.badge))),
                  const SizedBox(height: 8),
                  TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Siswa', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _savePresensi,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruColor),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Presensi', style: TextStyle(color: Colors.white)),
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
                .where('kelasId', isEqualTo: widget.kelasId)
                .where('recordedBy', isEqualTo: widget.teacherId)
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada presensi hari ini')));
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
                      leading: CircleAvatar(backgroundColor: color, child: Text(a.status[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      title: Text(a.studentName),
                      subtitle: Text(DateFormat('HH:mm').format(a.timestamp)),
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

  Future<void> _savePresensi() async {
    if (_namaCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection(AppConstants.attendanceCol).add(
        AttendanceModel(
          id: '',
          studentId: _nisCtrl.text,
          studentName: _namaCtrl.text,
          kelasId: widget.kelasId ?? '',
          status: _selectedStatus,
          timestamp: DateTime.now(),
          recordedBy: widget.teacherId ?? '',
        ).toMap(),
      );
      _nisCtrl.clear();
      _namaCtrl.clear();
      setState(() => _selectedStatus = 'HADIR');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Input Nilai ─────────────────────────────────────────────────────────────
class _NilaiTab extends StatefulWidget {
  final String? teacherId;
  final String? kelasId;
  const _NilaiTab({this.teacherId, this.kelasId});

  @override
  State<_NilaiTab> createState() => _NilaiTabState();
}

class _NilaiTabState extends State<_NilaiTab> {
  final _nisCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _mapelCtrl = TextEditingController();
  final _nilaiCtrl = TextEditingController();
  bool _saving = false;
  final _gradeRepo = GradeRepository();

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
                  const Text('Input Nilai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(controller: _nisCtrl, decoration: const InputDecoration(labelText: 'NIS Siswa', prefixIcon: Icon(Icons.badge))),
                  const SizedBox(height: 8),
                  TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Siswa', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 8),
                  TextField(controller: _mapelCtrl, decoration: const InputDecoration(labelText: 'Mata Pelajaran', prefixIcon: Icon(Icons.book))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nilaiCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Nilai (0-100)',
                      prefixIcon: Icon(Icons.grade),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveNilai,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruColor),
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Nilai', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nilai Tersimpan', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.kelasId != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _gradeRepo.watchByKelas(widget.kelasId!),
              builder: (context, snap) {
                final grades = snap.data ?? [];
                if (grades.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada nilai')));
                return Column(
                  children: grades.map((g) {
                    final nilai = (g['nilai'] as num?)?.toDouble() ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text(g['studentName'] ?? ''),
                        subtitle: Text(g['mapel'] ?? ''),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: nilai >= 75 ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            nilai.toStringAsFixed(0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: nilai >= 75 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
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

  Future<void> _saveNilai() async {
    if (_namaCtrl.text.isEmpty || _mapelCtrl.text.isEmpty || _nilaiCtrl.text.isEmpty) return;
    final nilai = double.tryParse(_nilaiCtrl.text);
    if (nilai == null || nilai < 0 || nilai > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai harus antara 0-100')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _gradeRepo.upsert(
        studentId: _nisCtrl.text,
        studentName: _namaCtrl.text,
        kelasId: widget.kelasId ?? '',
        mapel: _mapelCtrl.text,
        nilai: nilai,
        teacherId: widget.teacherId ?? '',
      );
      _nisCtrl.clear();
      _namaCtrl.clear();
      _nilaiCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai disimpan!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Kuis Tab wrapper ──────────────────────────────────────────────────────────
class _QuizTab extends StatelessWidget {
  final String teacherId;
  final String kelasId;
  const _QuizTab({required this.teacherId, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 64, color: AppTheme.guruColor),
            const SizedBox(height: 16),
            const Text('Buat dan kelola kuis untuk siswa', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => TeacherQuizPage(teacherId: teacherId, kelasId: kelasId),
              )),
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              label: const Text('Buka Manajemen Kuis', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruColor, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
