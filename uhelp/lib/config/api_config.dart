class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator, use localhost for web
  static const int connectTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000; // 15 seconds
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  
  // User endpoints
  static const String userProfile = '/users/profile';
  static const String changePassword = '/users/change-password';
  static const String userActivity = '/users/activity';
  
  // Problem endpoints
  static const String problems = '/problems';
  static const String problemCategories = '/problems/categories/all';
  static const String problemStatuses = '/problems/statuses/all';
  static const String checkSimilarProblems = '/problems/check-similar'; // Agregar este endpoint

  
  // Lost item endpoints
  static const String lostItems = '/lost-items';
  static const String lostItemStatuses = '/lost-items/statuses/all';
  
  // Notification endpoints
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String markAllRead = '/notifications/mark-all-read';
  
  // Announcement endpoints
  static const String announcements = '/announcements';
  static const String activeAnnouncements = '/announcements/active';
  
  // Map endpoints
  static const String locations = '/map/locations';
  static const String mapOverview = '/map/overview';
  
  // Admin endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminRoles = '/admin/roles';
  static const String adminProblems = '/admin/problems';
  static const String adminLostItems = '/admin/lost-items';
  static const String adminActivityLogs = '/admin/activity-logs';
  
  // Upload base URL
  static const String uploadBaseUrl = 'http://10.0.2.2:3000/uploads';
}