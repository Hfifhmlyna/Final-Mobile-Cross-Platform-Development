import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edutech_smk/core/router/app_router.dart';

enum UserRole {
  siswa('SISWA'),
  guruMapel('GURU_MAPEL'),
  waliKelas('WALI_KELAS'),
  guruBK('GURU_BK'),
  guruPiket('GURU_PIKET'),
  admin('ADMIN');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.siswa,
    );
  }
}

/// Model data pengguna dari Firestore
class UserModel {
  final String uid;
  final String email;
  final String nama;
  final UserRole role;
  final String? kelasId;
  final String? fotoUrl;

  const UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    this.kelasId,
    this.fotoUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nama: data['nama'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'SISWA'),
      kelasId: data['kelasId'],
      fotoUrl: data['fotoUrl'],
    );
  }
}

/// Service utama untuk Authentication dan Role-based Routing
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  AuthService() {
    // Listener perubahan state auth
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Dipanggil otomatis saat auth state berubah
  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _fetchUserData(user.uid);
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  /// Mengambil data user dari Firestore berdasarkan UID
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      _errorMessage = 'Gagal mengambil data pengguna: ${e.toString()}';
    }
  }

  /// Login dengan email dan password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _fetchUserData(credential.user!.uid);
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _errorMessage = _parseAuthError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Terjadi kesalahan yang tidak terduga.';
      notifyListeners();
      return false;
    }
  }

  /// Logout dan kembali ke halaman login
  Future<void> logout(BuildContext context) async {
    _setLoading(true);
    try {
      await _auth.signOut();
      _currentUser = null;
      _setLoading(false);
      if (context.mounted) {
        // Hapus seluruh stack dan kembali ke login
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Gagal logout: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Baca field 'role' dari Firestore lalu navigate ke dashboard sesuai role
  Future<void> navigateBasedOnRole(BuildContext context) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || !context.mounted) return;

      final roleStr = doc.data()?['role'] as String? ?? 'SISWA';
      final role = UserRole.fromString(roleStr);
      final route = AppRouter.routeForRole(role);

      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } catch (e) {
      _errorMessage = 'Gagal membaca data role: ${e.toString()}';
      notifyListeners();
    }
  }

  // Kept for backward-compat; prefer navigateBasedOnRole
  Widget _pageForRole(String role) => throw UnimplementedError();

  /// Parse error code Firebase Auth ke pesan user-friendly
  String _parseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi admin.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.';
      default:
        return 'Login gagal. Silakan coba lagi.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Reset password via email
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _errorMessage = _parseAuthError(e.code);
      notifyListeners();
      return false;
    }
  }
}
