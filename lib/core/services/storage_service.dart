import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload file PDF materi pelajaran, returns download URL
  Future<String> uploadMaterial({
    required String kelasId,
    required String mapel,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final ref = _storage.ref('materials/$kelasId/$mapel/$fileName');
    final task = await ref.putData(fileBytes, SettableMetadata(contentType: 'application/pdf'));
    return await task.ref.getDownloadURL();
  }

  /// Upload bukti pengerjaan tugas siswa, returns download URL
  Future<String> uploadSubmission({
    required String assignmentId,
    required String studentId,
    required String fileName,
    required Uint8List fileBytes,
    String contentType = 'application/pdf',
  }) async {
    final ref = _storage.ref('submissions/$assignmentId/$studentId/$fileName');
    final task = await ref.putData(fileBytes, SettableMetadata(contentType: contentType));
    return await task.ref.getDownloadURL();
  }

  /// Upload foto laporan piket, returns download URL
  Future<String> uploadPiketPhoto({
    required String date,
    required String teacherId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final ref = _storage.ref('piket_photos/$date/$teacherId/$fileName');
    final task = await ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
    return await task.ref.getDownloadURL();
  }

  /// Upload foto profil pengguna, returns download URL
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List fileBytes,
  }) async {
    final ref = _storage.ref('profile_photos/$userId/avatar.jpg');
    final task = await ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
    return await task.ref.getDownloadURL();
  }

  /// Upload file dari path (mobile only)
  Future<String> uploadFile({
    required String storagePath,
    required File file,
    String? contentType,
  }) async {
    final ref = _storage.ref(storagePath);
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;
    final task = metadata != null
        ? await ref.putFile(file, metadata)
        : await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  /// Hapus file dari Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {}
  }

  /// Stream progress upload (0.0 - 1.0)
  Stream<double> uploadWithProgress({
    required String storagePath,
    required Uint8List fileBytes,
    String contentType = 'application/octet-stream',
  }) {
    final ref = _storage.ref(storagePath);
    final task = ref.putData(fileBytes, SettableMetadata(contentType: contentType));
    return task.snapshotEvents.map((snap) {
      if (snap.totalBytes == 0) return 0.0;
      return snap.bytesTransferred / snap.totalBytes;
    });
  }
}
