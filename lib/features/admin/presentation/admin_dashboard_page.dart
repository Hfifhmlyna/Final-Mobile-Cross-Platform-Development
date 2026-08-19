import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;

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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduTech SMK — Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(auth.currentUser?.nama ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
            Tab(icon: Icon(Icons.dashboard), text: 'Ringkasan'),
            Tab(icon: Icon(Icons.people), text: 'Pengguna'),
            Tab(icon: Icon(Icons.settings), text: 'Pengaturan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RingkasanTab(db: _db),
          _PenggunaTab(db: _db),
          _PengaturanTab(),
        ],
      ),
    );
  }
}

// ── Ringkasan ──────────────────────────────────────────────────────────────
class _RingkasanTab extends StatelessWidget {
  final FirebaseFirestore db;
  const _RingkasanTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Statistik Sistem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatStreamCard(
                label: 'Total Siswa',
                stream: db.collection(AppConstants.usersCol).where('role', isEqualTo: 'SISWA').snapshots(),
                icon: Icons.school,
                color: AppTheme.siswaColor,
              ),
              _StatStreamCard(
                label: 'Total Guru',
                stream: db.collection(AppConstants.usersCol).where('role', whereIn: ['GURU_MAPEL', 'WALI_KELAS', 'GURU_BK', 'GURU_PIKET']).snapshots(),
                icon: Icons.person,
                color: AppTheme.guruColor,
              ),
              _StatStreamCard(
                label: 'Total Tugas',
                stream: db.collection(AppConstants.assignmentsCol).snapshots(),
                icon: Icons.assignment,
                color: Colors.orange,
              ),
              _StatStreamCard(
                label: 'Sesi BK',
                stream: db.collection(AppConstants.counselingCol).snapshots(),
                icon: Icons.psychology,
                color: AppTheme.bkColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Aktivitas Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection(AppConstants.attendanceCol).orderBy('timestamp', descending: true).limit(5).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.how_to_reg, color: AppTheme.guruColor),
                    title: Text(d['studentName'] ?? ''),
                    subtitle: Text('${d['kelasId']} • ${d['status']}'),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatStreamCard extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot> stream;
  final IconData icon;
  final Color color;
  const _StatStreamCard({required this.label, required this.stream, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Manajemen Pengguna ─────────────────────────────────────────────────────
class _PenggunaTab extends StatefulWidget {
  final FirebaseFirestore db;
  const _PenggunaTab({required this.db});

  @override
  State<_PenggunaTab> createState() => _PenggunaTabState();
}

class _PenggunaTabState extends State<_PenggunaTab> {
  String _filterRole = 'SEMUA';
  final _roles = ['SEMUA', 'SISWA', 'GURU_MAPEL', 'WALI_KELAS', 'GURU_BK', 'GURU_PIKET'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterRole,
                  decoration: const InputDecoration(labelText: 'Filter Role', isDense: true),
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _filterRole = v!),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _filterRole == 'SEMUA'
                ? widget.db.collection(AppConstants.usersCol).snapshots()
                : widget.db.collection(AppConstants.usersCol).where('role', isEqualTo: _filterRole).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('Tidak ada pengguna'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(d['role'] ?? '').withOpacity(0.15),
                        child: Text((d['nama'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(color: _roleColor(d['role'] ?? ''), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(d['nama'] ?? ''),
                      subtitle: Text('${d['email']} • ${d['role']}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) => _handleUserAction(context, action, docs[i].id, d),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Role')),
                          const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _roleColor(String role) => switch (role) {
        'SISWA' => AppTheme.siswaColor,
        'GURU_MAPEL' => AppTheme.guruColor,
        'WALI_KELAS' => AppTheme.waliColor,
        'GURU_BK' => AppTheme.bkColor,
        'GURU_PIKET' => AppTheme.piketColor,
        _ => Colors.grey,
      };

  void _handleUserAction(BuildContext context, String action, String uid, Map d) {
    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hapus Pengguna'),
          content: Text('Yakin hapus ${d['nama']}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                widget.db.collection(AppConstants.usersCol).doc(uid).delete();
                Navigator.pop(context);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else if (action == 'edit') {
      _showEditRoleDialog(context, uid, d);
    }
  }

  void _showEditRoleDialog(BuildContext context, String uid, Map d) {
    String selectedRole = d['role'] ?? 'SISWA';
    final editableRoles = ['SISWA', 'GURU_MAPEL', 'WALI_KELAS', 'GURU_BK', 'GURU_PIKET', 'ADMIN'];
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Edit Role: ${d['nama']}'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            items: editableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => selectedRole = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                widget.db.collection(AppConstants.usersCol).doc(uid).update({'role': selectedRole});
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    String selectedRole = 'SISWA';
    final roles = ['SISWA', 'GURU_MAPEL', 'WALI_KELAS', 'GURU_BK', 'GURU_PIKET'];
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (namaCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                widget.db.collection(AppConstants.usersCol).add({
                  'nama': namaCtrl.text,
                  'email': emailCtrl.text,
                  'role': selectedRole,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pengaturan ─────────────────────────────────────────────────────────────
class _PengaturanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = [
      {'title': 'Nama Sekolah', 'value': 'SMK Negeri 1', 'icon': Icons.school},
      {'title': 'Tahun Ajaran', 'value': '2025/2026', 'icon': Icons.calendar_today},
      {'title': 'Semester', 'value': 'Genap', 'icon': Icons.book},
      {'title': 'Threshold Alpha Alert', 'value': '3x', 'icon': Icons.warning},
      {'title': 'Threshold Nilai Drop', 'value': '20 poin', 'icon': Icons.trending_down},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Konfigurasi Sistem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...settings.map((s) => Card(
          child: ListTile(
            leading: Icon(s['icon'] as IconData, color: const Color(0xFF37474F)),
            title: Text(s['title'] as String),
            subtitle: Text(s['value'] as String),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () {},
          ),
        )),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.backup),
          label: const Text('Backup Data Firestore'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37474F)),
        ),
      ],
    );
  }
}
