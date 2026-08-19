import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

/// Halaman manajemen pelanggaran siswa — diakses dari BK, Wali Kelas, Piket
class ViolationPage extends StatefulWidget {
  final String? kelasId;
  final String recordedBy;
  const ViolationPage({super.key, this.kelasId, required this.recordedBy});

  @override
  State<ViolationPage> createState() => _ViolationPageState();
}

class _ViolationPageState extends State<ViolationPage> {
  final _db = FirebaseFirestore.instance;
  String _filterCategory = 'SEMUA';
  final _categories = ['SEMUA', 'KEDISIPLINAN', 'AKADEMIK', 'SOSIAL', 'LAINNYA'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bkColor,
        title: const Text('Manajemen Pelanggaran', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _filterCategory,
              decoration: const InputDecoration(labelText: 'Filter Kategori', isDense: true),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _filterCategory = v!),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    var query = _db.collection(AppConstants.violationsCol)
        .orderBy('timestamp', descending: true);
    if (widget.kelasId != null) {
      query = query.where('kelasId', isEqualTo: widget.kelasId) as Query<Map<String, dynamic>>;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snap.data?.docs ?? [];
        if (_filterCategory != 'SEMUA') {
          docs = docs.where((d) => (d.data() as Map)['category'] == _filterCategory).toList();
        }
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 12),
              Text('Tidak ada catatan pelanggaran'),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final v = ViolationModel.fromFirestore(docs[i]);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _pointColor(v.points).withOpacity(0.15),
                  child: Text('${v.points}', style: TextStyle(fontWeight: FontWeight.bold, color: _pointColor(v.points))),
                ),
                title: Text(v.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(children: [
                      _CategoryChip(v.category),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd MMM yyyy').format(v.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, docs[i].id, v.studentName),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _pointColor(int points) {
    if (points >= 50) return Colors.red;
    if (points >= 25) return Colors.orange;
    return Colors.amber;
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pelanggaran'),
        content: Text('Hapus catatan pelanggaran $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _db.collection(AppConstants.violationsCol).doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final namaCtrl = TextEditingController();
    final nisCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '5');
    String category = 'KEDISIPLINAN';
    final cats = ['KEDISIPLINAN', 'AKADEMIK', 'SOSIAL', 'LAINNYA'];
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Catat Pelanggaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nisCtrl, decoration: const InputDecoration(labelText: 'NIS Siswa')),
                const SizedBox(height: 8),
                TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Siswa')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi Pelanggaran')),
                const SizedBox(height: 8),
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Poin Pelanggaran'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bkColor),
              onPressed: () async {
                if (namaCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                await _db.collection(AppConstants.violationsCol).add(
                  ViolationModel(
                    id: '',
                    studentId: nisCtrl.text,
                    studentName: namaCtrl.text,
                    kelasId: widget.kelasId ?? '',
                    points: int.tryParse(pointsCtrl.text) ?? 5,
                    description: descCtrl.text,
                    category: category,
                    timestamp: DateTime.now(),
                    recordedBy: widget.recordedBy,
                  ).toMap(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip(this.category);

  Color get _color => switch (category) {
        'KEDISIPLINAN' => Colors.red,
        'AKADEMIK' => Colors.blue,
        'SOSIAL' => Colors.purple,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(category, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
