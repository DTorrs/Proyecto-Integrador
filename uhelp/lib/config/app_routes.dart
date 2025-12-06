import 'package:flutter/material.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/auth/screens/register_screen.dart';
import '../modules/auth/screens/profile_screen.dart';
import '../modules/problems/screens/problem_list_screen.dart';
import '../modules/problems/screens/problem_detail_screen.dart';
import '../modules/problems/screens/create_problem_screen.dart';
import '../modules/lost_items/screens/lost_item_list_screen.dart';
import '../modules/lost_items/screens/lost_item_detail_screen.dart';
import '../modules/lost_items/screens/create_lost_item_screen.dart';
import '../modules/map/screens/map_screen.dart';
import '../modules/notifications/screens/notification_screen.dart';
import '../modules/announcements/screens/announcement_list_screen.dart';
import '../modules/admin/screens/admin_dashboard.dart';

class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  
  // Main routes
  static const String home = '/home';
  static const String problemList = '/problems';
  static const String problemDetail = '/problems/detail';
  static const String createProblem = '/problems/create';
  static const String lostItemList = '/lost-items';
  static const String lostItemDetail = '/lost-items/detail';
  static const String createLostItem = '/lost-items/create';
  static const String map = '/map';
  static const String notifications = '/notifications';
  static const String announcements = '/announcements';
  
  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case problemList:
        return MaterialPageRoute(builder: (_) => ProblemListScreen());
      case problemDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => ProblemDetailScreen(problemId: args['problemId']));
      case createProblem:
        return MaterialPageRoute(builder: (_) => CreateProblemScreen());
      case lostItemList:
        return MaterialPageRoute(builder: (_) => LostItemListScreen());
      case lostItemDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => LostItemDetailScreen(itemId: args['itemId']));
      case createLostItem:
        return MaterialPageRoute(builder: (_) => CreateLostItemScreen());
      case map:
        return MaterialPageRoute(builder: (_) => MapScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => NotificationScreen());
      case announcements:
        return MaterialPageRoute(builder: (_) => AnnouncementListScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => AdminDashboard());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}