class AppConstants {
  // Firestore Collections
  static const String usersCol = 'users';
  static const String assignmentsCol = 'assignments';
  static const String attendanceCol = 'attendance';
  static const String violationsCol = 'violations';
  static const String counselingCol = 'counseling';
  static const String chatCol = 'chats';
  static const String notificationsCol = 'notifications';
  static const String piketLogCol = 'piket_logs';
  static const String quizzesCol = 'quizzes';
  static const String quizSubmissionsCol = 'quiz_submissions';

  // Storage Paths
  static const String materialsPath = 'materials';
  static const String submissionsPath = 'submissions';
  static const String piketPhotosPath = 'piket_photos';
  static const String profilePhotosPath = 'profile_photos';

  // Alert Thresholds
  static const int alphaAlertThreshold = 3;
  static const double gradeDropThreshold = 20.0;

  // FCM Topics
  static const String allTopic = 'all';
  static const String emergencyTopic = 'emergency';
}
