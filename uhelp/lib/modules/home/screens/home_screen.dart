import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/models/user_model.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../notifications/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final SocketService _socketService = SocketService();
  
  User? _currentUser;
  int _unreadNotifications = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeSocket();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load current user
      _currentUser = await _authService.getStoredUser();
      
      // Get fresh data from API
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        setState(() {
          _currentUser = userResponse.data;
        });
      }
      
      // Get unread notification count
      final notificationResponse = await _notificationService.getUnreadCount();
      if (notificationResponse.success && notificationResponse.data != null) {
        setState(() {
          _unreadNotifications = notificationResponse.data!;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeSocket() async {
    await _socketService.init('http://10.0.2.2:3000'); // Use your server URL
    
    // Join user-specific room for notifications
    if (_currentUser != null) {
      await _socketService.joinUserRoom(_currentUser!.id);
    }
    
    // Listen for notifications
    _socketService.listenForNotifications((data) {
      // Update unread count
      setState(() {
        _unreadNotifications++;
      });
      
      // Show notification
      _showNotification(data['message']);
    });
    
    // Listen for announcements
    _socketService.listenForAnnouncements((data) {
      // Show announcement
      _showNotification(data['message']);
    });
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UHelp'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications)
                      .then((_) => _loadData());
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(
        user: _currentUser,
        onLogout: () async {
          await _authService.logout();
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(16),
              children: [
                _buildMenuCard(
                  title: 'Problemas',
                  icon: Icons.warning,
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.problemList),
                ),
                _buildMenuCard(
                  title: 'Objetos Perdidos',
                  icon: Icons.search,
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.lostItemList),
                ),
                _buildMenuCard(
                  title: 'Mapa',
                  icon: Icons.map,
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.map),
                ),
                _buildMenuCard(
                  title: 'Anuncios',
                  icon: Icons.campaign,
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.announcements),
                ),
                if (_currentUser?.isStaffOrAdmin ?? false)
                  _buildMenuCard(
                    title: 'Admin',
                    icon: Icons.admin_panel_settings,
                    color: Colors.red,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
                  ),
                
              ],
            ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}