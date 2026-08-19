import 'package:flutter/material.dart';
import 'package:edutech_smk/core/services/auth_service.dart';
import 'package:edutech_smk/features/auth/presentation/pages/login_page.dart';
import 'package:edutech_smk/features/bk/presentation/bk_dashboard_page.dart';
import 'package:edutech_smk/features/piket/presentation/piket_dashboard_page.dart';
import 'package:edutech_smk/features/student/presentation/student_dashboard_page.dart';
import 'package:edutech_smk/features/teacher/presentation/teacher_dashboard_page.dart';
import 'package:edutech_smk/features/wali_kelas/presentation/wali_dashboard_page.dart';
import 'package:edutech_smk/features/admin/presentation/admin_dashboard_page.dart';
import 'package:edutech_smk/features/shared/profile_page.dart';

class AppRoutes {
  static const String login = '/';
  static const String studentDashboard = '/student';
  static const String teacherDashboard = '/teacher';
  static const String waliDashboard = '/wali';
  static const String bkDashboard = '/bk';
  static const String piketDashboard = '/piket';
  static const String adminDashboard = '/admin';
  static const String profile = '/profile';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _fade(const LoginPage());
      case AppRoutes.studentDashboard:
        return _fade(const StudentDashboardPage());
      case AppRoutes.teacherDashboard:
        return _fade(const TeacherDashboardPage());
      case AppRoutes.waliDashboard:
        return _fade(const WaliDashboardPage());
      case AppRoutes.bkDashboard:
        return _fade(const BkDashboardPage());
      case AppRoutes.piketDashboard:
        return _fade(const PiketDashboardPage());
      case AppRoutes.adminDashboard:
        return _fade(const AdminDashboardPage());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route tidak ditemukan: ${settings.name}')),
          ),
        );
    }
  }

  /// Route berdasarkan role user — dipanggil setelah login berhasil
  static String routeForRole(UserRole role) => switch (role) {
        UserRole.siswa => AppRoutes.studentDashboard,
        UserRole.guruMapel => AppRoutes.teacherDashboard,
        UserRole.waliKelas => AppRoutes.waliDashboard,
        UserRole.guruBK => AppRoutes.bkDashboard,
        UserRole.guruPiket => AppRoutes.piketDashboard,
        UserRole.admin => AppRoutes.adminDashboard,
      };

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );
}
