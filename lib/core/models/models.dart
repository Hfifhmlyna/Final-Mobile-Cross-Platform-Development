import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String? pdfUrl;
  final String? videoUrl;
  final String teacherId;
  final String kelasId;
  final String mapel;
  final DateTime dueDate;
  final DateTime createdAt;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    this.pdfUrl,
    this.videoUrl,
    required this.teacherId,
    required this.kelasId,
    required this.mapel,
    required this.dueDate,
    required this.createdAt,
  });

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      pdfUrl: d['pdfUrl'],
      videoUrl: d['videoUrl'],
      teacherId: d['teacherId'] ?? '',
      kelasId: d['kelasId'] ?? '',
      mapel: d['mapel'] ?? '',
      dueDate: (d['dueDate'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'pdfUrl': pdfUrl,
        'videoUrl': videoUrl,
        'teacherId': teacherId,
        'kelasId': kelasId,
        'mapel': mapel,
        'dueDate': Timestamp.fromDate(dueDate),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String kelasId;
  final String status; // HADIR, SAKIT, IZIN, ALPHA
  final String? keterangan;
  final DateTime timestamp;
  final String recordedBy;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.kelasId,
    required this.status,
    this.keterangan,
    required this.timestamp,
    required this.recordedBy,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      kelasId: d['kelasId'] ?? '',
      status: d['status'] ?? 'ALPHA',
      keterangan: d['keterangan'],
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      recordedBy: d['recordedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'kelasId': kelasId,
        'status': status,
        'keterangan': keterangan,
        'timestamp': Timestamp.fromDate(timestamp),
        'recordedBy': recordedBy,
      };
}

class ViolationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String kelasId;
  final int points;
  final String description;
  final String category; // KEDISIPLINAN, AKADEMIK, SOSIAL, LAINNYA
  final DateTime timestamp;
  final String recordedBy;

  const ViolationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.kelasId,
    required this.points,
    required this.description,
    required this.category,
    required this.timestamp,
    required this.recordedBy,
  });

  factory ViolationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ViolationModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      kelasId: d['kelasId'] ?? '',
      points: d['points'] ?? 0,
      description: d['description'] ?? '',
      category: d['category'] ?? 'LAINNYA',
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      recordedBy: d['recordedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'kelasId': kelasId,
        'points': points,
        'description': description,
        'category': category,
        'timestamp': Timestamp.fromDate(timestamp),
        'recordedBy': recordedBy,
      };
}

class CounselingModel {
  final String id;
  final String studentId;
  final String studentName;
  final String bkTeacherId;
  final String status; // MENUNGGU, DIJADWALKAN, SELESAI, DIBATALKAN
  final String? notes;
  final String? problemCategory; // AKADEMIK, SOSIAL, KELUARGA, KARIR, LAINNYA
  final DateTime requestDate;
  final DateTime? scheduledDate;
  final bool isConfidential;

  const CounselingModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.bkTeacherId,
    required this.status,
    this.notes,
    this.problemCategory,
    required this.requestDate,
    this.scheduledDate,
    this.isConfidential = true,
  });

  factory CounselingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CounselingModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      bkTeacherId: d['bkTeacherId'] ?? '',
      status: d['status'] ?? 'MENUNGGU',
      notes: d['notes'],
      problemCategory: d['problemCategory'],
      requestDate: (d['requestDate'] as Timestamp).toDate(),
      scheduledDate: d['scheduledDate'] != null
          ? (d['scheduledDate'] as Timestamp).toDate()
          : null,
      isConfidential: d['isConfidential'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'bkTeacherId': bkTeacherId,
        'status': status,
        'notes': notes,
        'problemCategory': problemCategory,
        'requestDate': Timestamp.fromDate(requestDate),
        'scheduledDate':
            scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
        'isConfidential': isConfidential,
      };

  CounselingModel copyWith({String? status, String? notes, DateTime? scheduledDate}) =>
      CounselingModel(
        id: id,
        studentId: studentId,
        studentName: studentName,
        bkTeacherId: bkTeacherId,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        problemCategory: problemCategory,
        requestDate: requestDate,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        isConfidential: isConfidential,
      );
}

// ── QuizModel ──────────────────────────────────────────────────────────────

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> d) => QuizQuestion(
        question: d['question'] ?? '',
        options: List<String>.from(d['options'] ?? []),
        correctIndex: d['correctIndex'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
      };
}

class QuizModel {
  final String id;
  final String title;
  final String mapel;
  final String kelasId;
  final String teacherId;
  final List<QuizQuestion> questions;
  final int durationMinutes;
  final DateTime? deadline;
  final DateTime createdAt;

  const QuizModel({
    required this.id,
    required this.title,
    required this.mapel,
    required this.kelasId,
    required this.teacherId,
    required this.questions,
    this.durationMinutes = 30,
    this.deadline,
    required this.createdAt,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      title: d['title'] ?? '',
      mapel: d['mapel'] ?? '',
      kelasId: d['kelasId'] ?? '',
      teacherId: d['teacherId'] ?? '',
      questions: (d['questions'] as List? ?? [])
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      durationMinutes: d['durationMinutes'] ?? 30,
      deadline: d['deadline'] != null ? (d['deadline'] as Timestamp).toDate() : null,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'mapel': mapel,
        'kelasId': kelasId,
        'teacherId': teacherId,
        'questions': questions.map((q) => q.toMap()).toList(),
        'durationMinutes': durationMinutes,
        'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class QuizSubmission {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final List<int> answers; // index jawaban per soal
  final int score;
  final DateTime submittedAt;

  const QuizSubmission({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.answers,
    required this.score,
    required this.submittedAt,
  });

  factory QuizSubmission.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuizSubmission(
      id: doc.id,
      quizId: d['quizId'] ?? '',
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      answers: List<int>.from(d['answers'] ?? []),
      score: d['score'] ?? 0,
      submittedAt: (d['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'quizId': quizId,
        'studentId': studentId,
        'studentName': studentName,
        'answers': answers,
        'score': score,
        'submittedAt': Timestamp.fromDate(submittedAt),
      };
}

