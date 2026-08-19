import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';

/// Provider untuk data assignment — dipakai guru dan siswa
class AssignmentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<AssignmentModel> _assignments = [];
  bool _loading = false;
  String? _error;

  List<AssignmentModel> get assignments => _assignments;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadByKelas(String kelasId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final snap = await _db
          .collection(AppConstants.assignmentsCol)
          .where('kelasId', isEqualTo: kelasId)
          .orderBy('createdAt', descending: true)
          .get();
      _assignments = snap.docs.map(AssignmentModel.fromFirestore).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> create(AssignmentModel assignment) async {
    final ref = await _db
        .collection(AppConstants.assignmentsCol)
        .add(assignment.toMap());
    await loadByKelas(assignment.kelasId);
    return ref.id;
  }

  Future<void> delete(String id, String kelasId) async {
    await _db.collection(AppConstants.assignmentsCol).doc(id).delete();
    _assignments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Stream<QuerySnapshot> streamByKelas(String kelasId) => _db
      .collection(AppConstants.assignmentsCol)
      .where('kelasId', isEqualTo: kelasId)
      .orderBy('createdAt', descending: true)
      .snapshots();
}

/// Provider untuk data attendance — dipakai guru, wali kelas, piket
class AttendanceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<AttendanceModel> _records = [];
  bool _loading = false;

  List<AttendanceModel> get records => _records;
  bool get loading => _loading;

  // Ringkasan kehadiran
  int get totalHadir => _records.where((r) => r.status == 'HADIR').length;
  int get totalAlpha => _records.where((r) => r.status == 'ALPHA').length;
  int get totalSakit => _records.where((r) => r.status == 'SAKIT').length;
  int get totalIzin => _records.where((r) => r.status == 'IZIN').length;

  Future<void> loadByKelas(String kelasId, {DateTime? from, DateTime? to}) async {
    _loading = true;
    notifyListeners();
    try {
      var query = _db
          .collection(AppConstants.attendanceCol)
          .where('kelasId', isEqualTo: kelasId);
      if (from != null) query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      if (to != null) query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to));
      final snap = await query.orderBy('timestamp', descending: true).get();
      _records = snap.docs.map(AttendanceModel.fromFirestore).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(AttendanceModel record) async {
    await _db.collection(AppConstants.attendanceCol).add(record.toMap());
    _records.insert(0, record);
    notifyListeners();
  }

  /// Siswa dengan alpha >= threshold
  Map<String, int> get alphaAlert {
    final Map<String, int> count = {};
    for (final r in _records.where((r) => r.status == 'ALPHA')) {
      count[r.studentId] = (count[r.studentId] ?? 0) + 1;
    }
    return Map.fromEntries(
      count.entries.where((e) => e.value >= AppConstants.alphaAlertThreshold),
    );
  }
}

/// Provider untuk data pelanggaran — dipakai BK, wali kelas, piket
class ViolationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<ViolationModel> _violations = [];
  bool _loading = false;

  List<ViolationModel> get violations => _violations;
  bool get loading => _loading;
  int get totalPoints => _violations.fold(0, (sum, v) => sum + v.points);

  Future<void> loadByStudent(String studentId) async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection(AppConstants.violationsCol)
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .get();
      _violations = snap.docs.map(ViolationModel.fromFirestore).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadByKelas(String kelasId) async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection(AppConstants.violationsCol)
          .where('kelasId', isEqualTo: kelasId)
          .orderBy('timestamp', descending: true)
          .get();
      _violations = snap.docs.map(ViolationModel.fromFirestore).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addViolation(ViolationModel violation) async {
    final ref = await _db.collection(AppConstants.violationsCol).add(violation.toMap());
    _violations.insert(0, ViolationModel(
      id: ref.id,
      studentId: violation.studentId,
      studentName: violation.studentName,
      kelasId: violation.kelasId,
      points: violation.points,
      description: violation.description,
      category: violation.category,
      timestamp: violation.timestamp,
      recordedBy: violation.recordedBy,
    ));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _db.collection(AppConstants.violationsCol).doc(id).delete();
    _violations.removeWhere((v) => v.id == id);
    notifyListeners();
  }
}

/// Provider untuk data konseling BK
class CounselingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<CounselingModel> _sessions = [];
  bool _loading = false;

  List<CounselingModel> get sessions => _sessions;
  bool get loading => _loading;
  int get pendingCount => _sessions.where((s) => s.status == 'MENUNGGU').length;
  int get activeCount => _sessions.where((s) => s.status == 'DIJADWALKAN').length;
  int get doneCount => _sessions.where((s) => s.status == 'SELESAI').length;

  Future<void> loadByBK(String bkId) async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection(AppConstants.counselingCol)
          .where('bkTeacherId', isEqualTo: bkId)
          .orderBy('requestDate', descending: true)
          .get();
      _sessions = snap.docs.map(CounselingModel.fromFirestore).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String id, String status, {String? notes, DateTime? scheduledDate}) async {
    final Map<String, dynamic> update = {'status': status};
    if (notes != null) update['notes'] = notes;
    if (scheduledDate != null) update['scheduledDate'] = Timestamp.fromDate(scheduledDate);
    await _db.collection(AppConstants.counselingCol).doc(id).update(update);
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(status: status, notes: notes, scheduledDate: scheduledDate);
      notifyListeners();
    }
  }
}
