import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';

/// Repository pattern — abstraksi akses data Firestore per fitur
/// Dipakai oleh Provider dan UI langsung

class AssignmentRepository {
  final _col = FirebaseFirestore.instance.collection(AppConstants.assignmentsCol);

  Stream<List<AssignmentModel>> watchByKelas(String kelasId) => _col
      .where('kelasId', isEqualTo: kelasId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AssignmentModel.fromFirestore).toList());

  Stream<List<AssignmentModel>> watchByTeacher(String teacherId) => _col
      .where('teacherId', isEqualTo: teacherId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AssignmentModel.fromFirestore).toList());

  Future<String> create(AssignmentModel a) async {
    final ref = await _col.add(a.toMap());
    return ref.id;
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}

class AttendanceRepository {
  final _col = FirebaseFirestore.instance.collection(AppConstants.attendanceCol);

  Stream<List<AttendanceModel>> watchByKelas(String kelasId, {DateTime? from}) {
    var q = _col.where('kelasId', isEqualTo: kelasId);
    if (from != null) q = q.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    return q.orderBy('timestamp', descending: true).snapshots()
        .map((s) => s.docs.map(AttendanceModel.fromFirestore).toList());
  }

  Stream<List<AttendanceModel>> watchByStudent(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AttendanceModel.fromFirestore).toList());

  Future<void> add(AttendanceModel record) => _col.add(record.toMap());

  /// Rekap alpha per siswa dalam satu kelas
  Future<Map<String, Map<String, dynamic>>> alphaRekapByKelas(String kelasId) async {
    final snap = await _col
        .where('kelasId', isEqualTo: kelasId)
        .where('status', isEqualTo: 'ALPHA')
        .get();
    final Map<String, Map<String, dynamic>> result = {};
    for (final doc in snap.docs) {
      final a = AttendanceModel.fromFirestore(doc);
      result[a.studentId] = {
        'nama': a.studentName,
        'count': (result[a.studentId]?['count'] as int? ?? 0) + 1,
      };
    }
    return result;
  }
}

class ViolationRepository {
  final _col = FirebaseFirestore.instance.collection(AppConstants.violationsCol);

  Stream<List<ViolationModel>> watchByKelas(String kelasId) => _col
      .where('kelasId', isEqualTo: kelasId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ViolationModel.fromFirestore).toList());

  Stream<List<ViolationModel>> watchByStudent(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ViolationModel.fromFirestore).toList());

  Future<void> add(ViolationModel v) => _col.add(v.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();
}

class CounselingRepository {
  final _col = FirebaseFirestore.instance.collection(AppConstants.counselingCol);

  Stream<List<CounselingModel>> watchByBK(String bkId) => _col
      .where('bkTeacherId', isEqualTo: bkId)
      .orderBy('requestDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CounselingModel.fromFirestore).toList());

  Stream<List<CounselingModel>> watchByStudent(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .orderBy('requestDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CounselingModel.fromFirestore).toList());

  Stream<List<CounselingModel>> watchPending() => _col
      .where('status', isEqualTo: 'MENUNGGU')
      .orderBy('requestDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CounselingModel.fromFirestore).toList());

  Future<String> request(CounselingModel c) async {
    final ref = await _col.add(c.toMap());
    return ref.id;
  }

  Future<void> updateStatus(String id, {
    required String status,
    String? notes,
    DateTime? scheduledDate,
    String? bkTeacherId,
  }) {
    final Map<String, dynamic> update = {'status': status};
    if (notes != null) update['notes'] = notes;
    if (bkTeacherId != null) update['bkTeacherId'] = bkTeacherId;
    if (scheduledDate != null) update['scheduledDate'] = Timestamp.fromDate(scheduledDate);
    return _col.doc(id).update(update);
  }
}

class GradeRepository {
  final _col = FirebaseFirestore.instance.collection('grades');

  Stream<List<Map<String, dynamic>>> watchByStudent(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchByKelas(String kelasId) => _col
      .where('kelasId', isEqualTo: kelasId)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> upsert({
    required String studentId,
    required String studentName,
    required String kelasId,
    required String mapel,
    required double nilai,
    required String teacherId,
  }) async {
    final snap = await _col
        .where('studentId', isEqualTo: studentId)
        .where('mapel', isEqualTo: mapel)
        .limit(1)
        .get();
    final data = {
      'studentId': studentId,
      'studentName': studentName,
      'kelasId': kelasId,
      'mapel': mapel,
      'nilai': nilai,
      'teacherId': teacherId,
      'updatedAt': Timestamp.now(),
    };
    if (snap.docs.isEmpty) {
      await _col.add({...data, 'createdAt': Timestamp.now()});
    } else {
      await _col.doc(snap.docs.first.id).update(data);
    }
  }
}
