import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edutech_smk/core/constants/app_constants.dart';
import 'package:edutech_smk/core/models/models.dart';
import 'package:edutech_smk/core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TEACHER: Halaman daftar + buat kuis
// ══════════════════════════════════════════════════════════════════════════════
class TeacherQuizPage extends StatelessWidget {
  final String teacherId;
  final String kelasId;
  const TeacherQuizPage({super.key, required this.teacherId, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.guruColor,
        title: const Text('Manajemen Kuis', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CreateQuizPage(teacherId: teacherId, kelasId: kelasId),
            )),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.quizzesCol)
            .where('teacherId', isEqualTo: teacherId)
            .orderBy('createdAt', descending: true)
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
                Icon(Icons.quiz, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada kuis. Tekan + untuk buat kuis baru.'),
              ],
            ));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final q = QuizModel.fromFirestore(docs[i]);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.guruColor,
                    child: Icon(Icons.quiz, color: Colors.white),
                  ),
                  title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${q.mapel} • ${q.questions.length} soal • ${q.durationMinutes} menit'),
                      if (q.deadline != null)
                        Text('Deadline: ${DateFormat('dd MMM yyyy').format(q.deadline!)}',
                            style: TextStyle(color: q.deadline!.isBefore(DateTime.now()) ? Colors.red : Colors.grey, fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart, color: AppTheme.guruColor),
                        tooltip: 'Lihat Hasil',
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => QuizResultsPage(quizId: docs[i].id, quizTitle: q.title),
                        )),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, docs[i].id, q.title),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kuis'),
        content: Text('Hapus kuis "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection(AppConstants.quizzesCol).doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TEACHER: Buat kuis baru dengan builder soal
// ══════════════════════════════════════════════════════════════════════════════
class CreateQuizPage extends StatefulWidget {
  final String teacherId;
  final String kelasId;
  const CreateQuizPage({super.key, required this.teacherId, required this.kelasId});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _titleCtrl = TextEditingController();
  final _mapelCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _formKey = GlobalKey<FormState>();
  final List<_QuestionDraft> _questions = [];
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.guruColor,
        title: const Text('Buat Kuis Baru', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Kuis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Judul Kuis *'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mapelCtrl,
                      decoration: const InputDecoration(labelText: 'Mata Pelajaran *'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Durasi (menit)', suffixText: 'menit'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Soal (${_questions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah Soal'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._questions.asMap().entries.map((e) => _QuestionCard(
              index: e.key,
              draft: e.value,
              onDelete: () => setState(() => _questions.removeAt(e.key)),
              onUpdate: () => setState(() {}),
            )),
            if (_questions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Belum ada soal. Tekan "Tambah Soal".', style: TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft()));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambah minimal 1 soal')));
      return;
    }
    for (final q in _questions) {
      if (q.questionCtrl.text.isEmpty || q.options.any((o) => o.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua soal dan pilihan jawaban')));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final quiz = QuizModel(
        id: '',
        title: _titleCtrl.text,
        mapel: _mapelCtrl.text,
        kelasId: widget.kelasId,
        teacherId: widget.teacherId,
        questions: _questions.map((q) => QuizQuestion(
          question: q.questionCtrl.text,
          options: q.options.map((o) => o.text).toList(),
          correctIndex: q.correctIndex,
        )).toList(),
        durationMinutes: int.tryParse(_durationCtrl.text) ?? 30,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance.collection(AppConstants.quizzesCol).add(quiz.toMap());
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _QuestionDraft {
  final questionCtrl = TextEditingController();
  final List<TextEditingController> options = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;
}

class _QuestionCard extends StatefulWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  const _QuestionCard({required this.index, required this.draft, required this.onDelete, required this.onUpdate});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: AppTheme.guruColor, child: Text('${widget.index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                const SizedBox(width: 8),
                const Expanded(child: Text('Soal', style: TextStyle(fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: widget.onDelete),
              ],
            ),
            TextField(
              controller: widget.draft.questionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Tulis pertanyaan...', isDense: true),
            ),
            const SizedBox(height: 8),
            const Text('Pilihan Jawaban (pilih yang benar):', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ...List.generate(4, (i) => Row(
              children: [
                Radio<int>(
                  value: i,
                  groupValue: widget.draft.correctIndex,
                  activeColor: AppTheme.guruColor,
                  onChanged: (v) => setState(() => widget.draft.correctIndex = v!),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.draft.options[i],
                    decoration: InputDecoration(
                      hintText: 'Pilihan ${String.fromCharCode(65 + i)}',
                      isDense: true,
                      border: const UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: i == widget.draft.correctIndex ? AppTheme.guruColor : Colors.grey)),
                    ),
                  ),
                ),
                if (i == widget.draft.correctIndex)
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TEACHER: Hasil kuis per siswa
// ══════════════════════════════════════════════════════════════════════════════
class QuizResultsPage extends StatelessWidget {
  final String quizId;
  final String quizTitle;
  const QuizResultsPage({super.key, required this.quizId, required this.quizTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.guruColor,
        title: Text('Hasil: $quizTitle', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.quizSubmissionsCol)
            .where('quizId', isEqualTo: quizId)
            .orderBy('score', descending: true)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Belum ada siswa yang mengerjakan'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final s = QuizSubmission.fromFirestore(docs[i]);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.score >= 70 ? Colors.green : Colors.orange,
                    child: Text('${s.score}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(s.studentName),
                  subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(s.submittedAt)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STUDENT: Daftar kuis + pengerjaan
// ══════════════════════════════════════════════════════════════════════════════
class StudentQuizPage extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String kelasId;
  const StudentQuizPage({super.key, required this.studentId, required this.studentName, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.siswaColor,
        title: const Text('Daftar Kuis', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.quizzesCol)
            .where('kelasId', isEqualTo: kelasId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Belum ada kuis'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final q = QuizModel.fromFirestore(docs[i]);
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection(AppConstants.quizSubmissionsCol)
                    .where('quizId', isEqualTo: docs[i].id)
                    .where('studentId', isEqualTo: studentId)
                    .limit(1)
                    .get(),
                builder: (context, subSnap) {
                  final submitted = subSnap.data?.docs.isNotEmpty == true;
                  final score = submitted
                      ? QuizSubmission.fromFirestore(subSnap.data!.docs.first).score
                      : null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: submitted ? Colors.green : AppTheme.siswaColor,
                        child: Icon(submitted ? Icons.check : Icons.quiz, color: Colors.white),
                      ),
                      title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${q.mapel} • ${q.questions.length} soal • ${q.durationMinutes} menit'),
                      trailing: submitted
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: score! >= 70 ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$score', style: TextStyle(fontWeight: FontWeight.bold, color: score >= 70 ? Colors.green : Colors.orange)),
                            )
                          : ElevatedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => TakeQuizPage(
                                  quiz: q,
                                  quizId: docs[i].id,
                                  studentId: studentId,
                                  studentName: studentName,
                                ),
                              )),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.siswaColor),
                              child: const Text('Kerjakan', style: TextStyle(color: Colors.white)),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STUDENT: Mengerjakan kuis dengan timer
// ══════════════════════════════════════════════════════════════════════════════
class TakeQuizPage extends StatefulWidget {
  final QuizModel quiz;
  final String quizId;
  final String studentId;
  final String studentName;
  const TakeQuizPage({super.key, required this.quiz, required this.quizId, required this.studentId, required this.studentName});

  @override
  State<TakeQuizPage> createState() => _TakeQuizPageState();
}

class _TakeQuizPageState extends State<TakeQuizPage> {
  late List<int?> _answers;
  late int _secondsLeft;
  Timer? _timer;
  bool _submitted = false;
  int? _finalScore;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quiz.questions.length, null);
    _secondsLeft = widget.quiz.durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _submit();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildResult();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.siswaColor,
        title: Text(widget.quiz.title, style: const TextStyle(color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _secondsLeft < 60 ? Colors.red : Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.timer, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(_timeDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _answers.where((a) => a != null).length / widget.quiz.questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.siswaColor),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.quiz.questions.length,
              itemBuilder: (context, i) {
                final q = widget.quiz.questions[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(radius: 12, backgroundColor: AppTheme.siswaColor,
                              child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(q.question, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ]),
                        const SizedBox(height: 12),
                        ...List.generate(q.options.length, (j) => RadioListTile<int>(
                          dense: true,
                          activeColor: AppTheme.siswaColor,
                          title: Text('${String.fromCharCode(65 + j)}. ${q.options[j]}'),
                          value: j,
                          groupValue: _answers[i],
                          onChanged: (v) => setState(() => _answers[i] = v),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answers.any((a) => a == null) ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.siswaColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(
                  _answers.where((a) => a != null).length < widget.quiz.questions.length
                      ? 'Jawab semua soal terlebih dahulu (${_answers.where((a) => a != null).length}/${widget.quiz.questions.length})'
                      : 'Kumpulkan Jawaban',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final pct = (_finalScore! / 100);
    final passed = _finalScore! >= 70;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.siswaColor,
        title: const Text('Hasil Kuis', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 80, color: passed ? Colors.amber : Colors.orange),
              const SizedBox(height: 16),
              Text('$_finalScore', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold,
                  color: passed ? Colors.green : Colors.orange)),
              const Text('Skor Kamu', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(passed ? 'Selamat! Kamu LULUS 🎉' : 'Terus semangat belajar!',
                  style: TextStyle(fontSize: 18, color: passed ? Colors.green : Colors.orange)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.siswaColor),
                child: const Text('Kembali ke Daftar Kuis', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _timer?.cancel();
    int correct = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_answers[i] == widget.quiz.questions[i].correctIndex) correct++;
    }
    final score = ((correct / widget.quiz.questions.length) * 100).round();
    await FirebaseFirestore.instance.collection(AppConstants.quizSubmissionsCol).add(
      QuizSubmission(
        id: '',
        quizId: widget.quizId,
        studentId: widget.studentId,
        studentName: widget.studentName,
        answers: _answers.map((a) => a ?? -1).toList(),
        score: score,
        submittedAt: DateTime.now(),
      ).toMap(),
    );
    setState(() {
      _submitted = true;
      _finalScore = score;
    });
  }
}
