import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/services/fcm_service.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

/// Panel notifikasi in-app — tampilkan sebagai bottom sheet atau halaman
class NotificationPanel extends StatelessWidget {
  final String userId;
  const NotificationPanel({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _markAllRead(),
            child: const Text('Tandai Semua Baca', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.notificationsCol)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
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
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Tidak ada notifikasi'),
              ],
            ));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final isRead = d['isRead'] as bool? ?? false;
              final type = d['type'] as String? ?? 'INFO';
              final createdAt = d['createdAt'] as Timestamp?;
              return ListTile(
                tileColor: isRead ? null : AppTheme.primary.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: _typeColor(type).withOpacity(0.15),
                  child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
                ),
                title: Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['body'] ?? ''),
                    if (createdAt != null)
                      Text(
                        DateFormat('dd MMM HH:mm').format(createdAt.toDate()),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: !isRead
                    ? const Icon(Icons.circle, color: AppTheme.primary, size: 10)
                    : null,
                onTap: () => FCMService().markAsRead(docs[i].id),
              );
            },
          );
        },
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
        'TUGAS' => Colors.blue,
        'PRESENSI' => Colors.green,
        'DARURAT' => Colors.red,
        'KONSELING' => AppTheme.bkColor,
        _ => Colors.grey,
      };

  IconData _typeIcon(String type) => switch (type) {
        'TUGAS' => Icons.assignment,
        'PRESENSI' => Icons.how_to_reg,
        'DARURAT' => Icons.warning,
        'KONSELING' => Icons.psychology,
        _ => Icons.notifications,
      };

  Future<void> _markAllRead() async {
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCol)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

/// Badge widget untuk icon notifikasi di AppBar
class NotificationBadge extends StatelessWidget {
  final String userId;
  final VoidCallback onTap;
  const NotificationBadge({super.key, required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FCMService().unreadNotificationsStream(userId),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: onTap,
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
