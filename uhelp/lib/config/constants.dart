class AppConstants {
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Roles
  static const int roleStudent = 1;
  static const int roleStaff = 2;
  static const int roleAdmin = 3;
  
  // Status IDs
  static const int problemStatusPending = 1;
  static const int problemStatusInProgress = 2;
  static const int problemStatusResolved = 3;
  
  static const int lostItemStatusReported = 1;
  static const int lostItemStatusInD300 = 2;
  static const int lostItemStatusClaimed = 3;
  static const int lostItemStatusArchived = 4;
  
  // Pagination defaults
  static const int defaultPageSize = 10;
  
  // Socket events
  static const String socketEventNotification = 'notification';
  static const String socketEventAnnouncement = 'announcement';
}