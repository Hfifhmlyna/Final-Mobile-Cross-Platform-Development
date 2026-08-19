import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';
import 'package:edutech_smk/features/shared/quiz_pages.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        backgroundColor: AppTheme.siswaColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduTech SMK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Siswa: ${user?.nama ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => auth.logout(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Materi'),
            Tab(icon: Icon(Icons.assignment), text: 'Tugas'),
            Tab(icon: Icon(Icons.quiz), text: 'Kuis'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Nilai'),
            Tab(icon: Icon(Icons.psychology), text: 'Konseling'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MateriTab(kelasId: user?.kelasId),
          _TugasTab(kelasId: user?.kelasId),
          _KuisTab(studentId: user?.uid ?? '', studentName: user?.nama ?? '', kelasId: user?.kelasId ?? ''),
          _NilaiTab(studentId: user?.uid),
          _KonselingTab(studentId: user?.uid, studentName: user?.nama ?? ''),
        ],
      ),
    );
  }
}

// ── Tab Materi ──────────────────────────────────────────────────────────────
class _MateriTab extends StatelessWidget {
  final String? kelasId;
  const _MateriTab({this.kelasId});

  @override
  Widget build(BuildContext context) {
    if (kelasId == null) return const Center(child: Text('Kelas belum ditentukan'));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.assignmentsCol)
          .where('kelasId', isEqualTo: kelasId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        // Sort di Dart — tidak butuh composite index
        docs.sort((a, b) {
          final ta = (a.data() as Map)['createdAt'];
          final tb = (b.data() as Map)['createdAt'];
          if (ta == null || tb == null) return 0;
          return (tb as Timestamp).compareTo(ta as Timestamp);
        });
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('Belum ada materi'),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final a = AssignmentModel.fromFirestore(docs[i]);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.siswaColor,
                  child: Icon(Icons.picture_as_pdf, color: Colors.white),
                ),
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(a.mapel),
                trailing: a.pdfUrl != null
                    ? const Icon(Icons.download, color: AppTheme.siswaColor)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

// ── Tab Tugas ───────────────────────────────────────────────────────────────
class _TugasTab extends StatelessWidget {
  final String? kelasId;
  const _TugasTab({this.kelasId});

  @override
  Widget build(BuildContext context) {
    if (kelasId == null) return const Center(child: Text('Kelas belum ditentukan'));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.assignmentsCol)
          .where('kelasId', isEqualTo: kelasId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        // Sort by dueDate di Dart
        docs.sort((a, b) {
          final ta = (a.data() as Map)['dueDate'];
          final tb = (b.data() as Map)['dueDate'];
          if (ta == null || tb == null) return 0;
          return (ta as Timestamp).compareTo(tb as Timestamp);
        });
        if (docs.isEmpty) return const Center(child: Text('Belum ada tugas'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final a = AssignmentModel.fromFirestore(docs[i]);
            final isOverdue = a.dueDate.isBefore(DateTime.now());
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOverdue ? Colors.red : AppTheme.siswaColor,
                  child: const Icon(Icons.assignment, color: Colors.white),
                ),
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.mapel),
                    Text(
                      'Deadline: ${DateFormat('dd MMM yyyy').format(a.dueDate)}',
                      style: TextStyle(color: isOverdue ? Colors.red : Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _showUploadDialog(context, a),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.siswaColor),
                  child: const Text('Kumpul', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUploadDialog(BuildContext context, AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Kumpul: ${assignment.title}'),
        content: const Text('Pilih file PDF untuk dikumpulkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Upload')),
        ],
      ),
    );
  }
}

// ── Tab Nilai ───────────────────────────────────────────────────────────────
class _NilaiTab extends StatelessWidget {
  final String? studentId;
  const _NilaiTab({this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('Belum ada rekap nilai'),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final nilai = data['nilai'] as num? ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(data['mapel'] ?? ''),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: nilai >= 75 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$nilai', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Tab Konseling ────────────────────────────────────────────────────────────
class _KonselingTab extends StatelessWidget {
  final String? studentId;
  final String studentName;
  const _KonselingTab({this.studentId, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppTheme.bkColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.psychology, color: AppTheme.bkColor),
                    SizedBox(width: 8),
                    Text('Booking Sesi BK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Semua sesi konseling bersifat rahasia (confidential).'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showBookingDialog(context),
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: const Text('Ajukan Konseling', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bkColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Riwayat Konseling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.counselingCol)
                  .where('studentId', isEqualTo: studentId)
                  .orderBy('requestDate', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Belum ada riwayat konseling'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final c = CounselingModel.fromFirestore(docs[i]);
                    return Card(
                      child: ListTile(
                        title: Text(c.problemCategory ?? 'Konseling Umum'),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(c.requestDate)),
                        trailing: _StatusChip(status: c.status),
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

  void _showBookingDialog(BuildContext context) {
    final categories = ['AKADEMIK', 'SOSIAL', 'KELUARGA', 'KARIR', 'LAINNYA'];
    String? selected;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajukan Konseling'),
          content: DropdownButtonFormField<String>(
            hint: const Text('Pilih kategori masalah'),
            value: selected,
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: selected == null ? null : () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permintaan konseling dikirim')),
                );
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
        'DIJADWALKAN' => Colors.blue,
        'SELESAI' => Colors.green,
        'DIBATALKAN' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Tab Kuis ─────────────────────────────────────────────────────────────────
class _KuisTab extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String kelasId;
  const _KuisTab({required this.studentId, required this.studentName, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 64, color: AppTheme.siswaColor),
            const SizedBox(height: 16),
            const Text('Kerjakan kuis yang diberikan oleh guru', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudentQuizPage(
                  studentId: studentId,
                  studentName: studentName,
                  kelasId: kelasId,
                ),
              )),
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              label: const Text('Buka Daftar Kuis', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.siswaColor, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
