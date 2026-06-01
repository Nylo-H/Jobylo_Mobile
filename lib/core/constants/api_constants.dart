class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'http://192.168.43.20:8080/api'; // 192.168.43.20
  static const String wsUrl = 'ws://192.168.43.20:8080/api/ws';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // Jobs
  static const String jobs = '/jobs';
  static const String jobsAvailable = '/jobs/available';
  static const String jobsMyCreated = '/jobs/my-created';
  static const String jobsMyAssigned = '/jobs/my-assigned';

  // Messages
  static const String messages = '/messages';
  static const String conversations = '/messages/conversations';
  static const String unreadCount = '/messages/unread-count';
  static const String messagesStart = '/messages/start';
  static const String messagesConversation = '/messages/conversation';

  // Profile
  static const String profilePhoto = '/auth/profile/photo';

  // Ratings
  static const String ratings = '/ratings';

  // Categories
  static const String categoriesTree = '/categories/tree';
  static const String categories = '/categories';

  // Payments
  static const String payments = '/payments';
  static const String paymentsConfirm = '/payments/confirm';

  // KYC
  static const String kycUpload = '/kyc/upload';
  static const String kycStatus = '/kyc/status';

  // Password Reset
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Users
  static const String users = '/users';
}
