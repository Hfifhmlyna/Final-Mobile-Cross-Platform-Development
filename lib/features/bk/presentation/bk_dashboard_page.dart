import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

import 'package:edutech_smk/features/bk/presentation/violation_page.dart';

class BkDashboardPage extends StatefulWidget {
  const BkDashboardPage({super.key});

  @override
  State<BkDashboardPage> createState() => _BkDashboardPageState();
}

class _BkDashboardPageState extends State<BkDashboardPage>
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
        backgroundColor: AppTheme.bkColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduTech SMK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Guru BK: ${user?.nama ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: Colors.white),
            tooltip: 'Pelanggaran',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ViolationPage(recordedBy: user?.uid ?? ''),
            )),
          ),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => auth.logout(context)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Permintaan'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.track_changes), text: 'Tracking'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PermintaanTab(bkId: user?.uid),
          _ChatTab(bkId: user?.uid, bkName: user?.nama ?? ''),
          _TrackingTab(bkId: user?.uid),
        ],
      ),
    );
  }
}

// ── Permintaan Konseling ────────────────────────────────────────────────────
class _PermintaanTab extends StatelessWidget {
  final String? bkId;
  const _PermintaanTab({this.bkId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.counselingCol)
          .where('status', isEqualTo: 'MENUNGGU')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('Tidak ada permintaan konseling'),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final c = CounselingModel.fromFirestore(docs[i]);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.bkColor,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(c.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori: ${c.problemCategory ?? 'Umum'}'),
                    Text('Tanggal: ${DateFormat('dd MMM yyyy').format(c.requestDate)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Jadwalkan',
                      onPressed: () => _jadwalkan(context, docs[i].id, c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Batalkan',
                      onPressed: () => FirebaseFirestore.instance
                          .collection(AppConstants.counselingCol)
                          .doc(docs[i].id)
                          .update({'status': 'DIBATALKAN', 'bkTeacherId': bkId}),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _jadwalkan(BuildContext context, String docId, CounselingModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Jadwalkan Konseling'),
        content: Text('Jadwalkan sesi untuk ${c.studentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection(AppConstants.counselingCol)
                  .doc(docId)
                  .update({
                'status': 'DIJADWALKAN',
                'bkTeacherId': bkId,
                'scheduledDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
              });
              Navigator.pop(context);
            },
            child: const Text('Jadwalkan'),
          ),
        ],
      ),
    );
  }
}

// ── Chat Confidential ────────────────────────────────────────────────────────
class _ChatTab extends StatelessWidget {
  final String? bkId;
  final String bkName;
  const _ChatTab({this.bkId, required this.bkName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.counselingCol)
          .where('bkTeacherId', isEqualTo: bkId)
          .where('status', isEqualTo: 'DIJADWALKAN')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('Tidak ada sesi aktif'),
              Text('Chat hanya tersedia untuk sesi yang dijadwalkan', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final c = CounselingModel.fromFirestore(docs[i]);
            return Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.bkColor, child: Icon(Icons.chat, color: Colors.white)),
                title: Text(c.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('🔒 Chat Confidential'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openChat(context, c),
              ),
            );
          },
        );
      },
    );
  }

  void _openChat(BuildContext context, CounselingModel c) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ChatRoomPage(counseling: c, bkId: bkId ?? ''),
    ));
  }
}

class _ChatRoomPage extends StatefulWidget {
  final CounselingModel counseling;
  final String bkId;
  const _ChatRoomPage({required this.counseling, required this.bkId});

  @override
  State<_ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<_ChatRoomPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String get _chatId => 'bk_${widget.counseling.studentId}_${widget.bkId}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bkColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.counseling.studentName, style: const TextStyle(color: Colors.white)),
            const Text('🔒 Confidential', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.chatCol)
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Belum ada pesan'));
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = docs[i].data() as Map<String, dynamic>;
                    final isMine = msg['senderId'] == widget.bkId;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMine ? AppTheme.bkColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg['text'] ?? '', style: TextStyle(color: isMine ? Colors.white : Colors.black87)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(hintText: 'Tulis pesan...', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.bkColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.isEmpty) return;
    final text = _msgCtrl.text;
    _msgCtrl.clear();
    await FirebaseFirestore.instance
        .collection(AppConstants.chatCol)
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderId': widget.bkId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

// ── Tracking Kasus ──────────────────────────────────────────────────────────
class _TrackingTab extends StatelessWidget {
  final String? bkId;
  const _TrackingTab({this.bkId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.counselingCol)
          .where('bkTeacherId', isEqualTo: bkId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;
        final selesai = docs.where((d) => (d.data() as Map)['status'] == 'SELESAI').length;
        final aktif = docs.where((d) => (d.data() as Map)['status'] == 'DIJADWALKAN').length;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                _TrackCard('Total Kasus', total, Colors.purple),
                const SizedBox(width: 8),
                _TrackCard('Aktif', aktif, Colors.blue),
                const SizedBox(width: 8),
                _TrackCard('Selesai', selesai, Colors.green),
              ]),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('Semua Kasus', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('Belum ada kasus'))
                    : ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final c = CounselingModel.fromFirestore(docs[i]);
                          return Card(
                            child: ListTile(
                              title: Text(c.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${c.problemCategory ?? 'Umum'} • ${DateFormat('dd MMM yyyy').format(c.requestDate)}'),
                              trailing: _buildStatusChip(c.status),
                              onTap: () => _showDetail(context, docs[i].id, c),
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

  Widget _buildStatusChip(String status) {
    final color = switch (status) {
      'SELESAI' => Colors.green,
      'DIJADWALKAN' => Colors.blue,
      'DIBATALKAN' => Colors.red,
      _ => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showDetail(BuildContext context, String id, CounselingModel c) {
    final notesCtrl = TextEditingController(text: c.notes);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(c.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Catatan Kasus', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection(AppConstants.counselingCol).doc(id)
                        .update({'notes': notesCtrl.text, 'status': 'SELESAI'});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Tandai Selesai', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection(AppConstants.counselingCol).doc(id)
                        .update({'notes': notesCtrl.text});
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Catatan'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _TrackCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
