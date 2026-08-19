import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';

// Background handler hanya aktif di mobile/desktop
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background: ${message.notification?.title}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inisialisasi FCM — aman untuk semua platform
  Future<void> initialize() async {
    try {
      // Minta izin notifikasi
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Background handler hanya didukung mobile — skip di web
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      // Handler pesan foreground
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('FCM Foreground: ${message.notification?.title}');
      });

      // Topic subscription tidak didukung web
      if (!kIsWeb) {
        await _messaging.subscribeToTopic(AppConstants.allTopic);
      }
    } catch (e) {
      // Jangan biarkan FCM error menghentikan app
      debugPrint('FCM init error (non-fatal): $e');
    }
  }

  /// Simpan FCM token ke Firestore profil user
  Future<void> saveTokenToFirestore(String userId) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore
        .collection(AppConstants.usersCol)
        .doc(userId)
        .update({'fcmToken': token});

    // Refresh token listener
    _messaging.onTokenRefresh.listen((newToken) {
      _firestore
          .collection(AppConstants.usersCol)
          .doc(userId)
          .update({'fcmToken': newToken});
    });
  }

  /// Subscribe ke topic role tertentu (e.g. 'SISWA', 'GURU_MAPEL')
  Future<void> subscribeToRoleTopic(String role) async {
    await _messaging.subscribeToTopic(role.toLowerCase());
  }

  /// Subscribe ke topic kelas (e.g. 'kelas_X_TKJ_1')
  Future<void> subscribeToClassTopic(String kelasId) async {
    await _messaging.subscribeToTopic('kelas_$kelasId');
  }

  /// Unsubscribe dari semua topic (saat logout)
  Future<void> unsubscribeAll(String role, String? kelasId) async {
    await _messaging.unsubscribeFromTopic(AppConstants.allTopic);
    await _messaging.unsubscribeFromTopic(role.toLowerCase());
    if (kelasId != null) {
      await _messaging.unsubscribeFromTopic('kelas_$kelasId');
    }
  }

  /// Simpan notifikasi ke Firestore (untuk in-app notification center)
  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    required String type, // 'TUGAS', 'PRESENSI', 'DARURAT', 'KONSELING'
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection(AppConstants.notificationsCol).add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Broadcast emergency notification ke semua user via Firestore trigger
  Future<void> broadcastEmergency({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    await _firestore.collection('emergency_broadcasts').add({
      'title': title,
      'body': body,
      'sentBy': sentBy,
      'sentAt': FieldValue.serverTimestamp(),
      'topic': AppConstants.emergencyTopic,
    });
  }

  /// Stream notifikasi belum dibaca untuk user tertentu
  Stream<QuerySnapshot> unreadNotificationsStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCol)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Tandai notifikasi sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCol)
        .doc(notificationId)
        .update({'isRead': true});
  }
}
