import 'package:flutter/material.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../services/admin_service.dart';
import '../models/admin_model.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/helper_functions.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  AdminDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data
      _currentUser = await _authService.getStoredUser();
      
      if (_currentUser == null || !_currentUser!.isStaffOrAdmin) {
        setState(() {
          _errorMessage = 'You do not have permission to access this page.';
        });
        return;
      }
      
      // Load dashboard statistics
      final response = await _adminService.getDashboardStats();
      if (response.success && response.data != null) {
        setState(() {
          _stats = response.data;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Admin Dashboard',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadData,
      drawer: AppDrawer(
        user: _currentUser,
        onLogout: () async {
          await _authService.logout();
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
      ),
      body: _stats == null
          ? Container()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                SizedBox(height: 16),
                _buildProblemsStatusCard(),
                SizedBox(height: 16),
                _buildLostItemsStatusCard(),
                SizedBox(height: 16),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildRecentActivityList(),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Users',
                  _stats!.totalUsers.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Total Problems',
                  _stats!.problemsByStatus
                      .fold(0, (sum, item) => sum + item.count)
                      .toString(),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Total Lost Items',
                  _stats!.lostItems
                      .fold(0, (sum, item) => sum + item.count)
                      .toString(),
                  Icons.search,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProblemsStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Problems by Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _stats!.problemsByStatus.map((status) {
                Color color;
                switch (status.name.toLowerCase()) {
                  case 'pendiente':
                    color = AppTheme.pendingColor;
                    break;
                  case 'en progreso':
                    color = AppTheme.inProgressColor;
                    break;
                  case 'resuelto':
                    color = AppTheme.resolvedColor;
                    break;
                  default:
                    color = Colors.grey;
                }
                
                return _buildStatusItem(
                  status.name,
                  status.count.toString(),
                  color,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostItemsStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lost & Found Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _stats!.lostItems.map((status) {
                Color color;
                switch (status.name.toLowerCase()) {
                  case 'reportado':
                    color = AppTheme.pendingColor;
                    break;
                  case 'Sotano D':
                    color = AppTheme.inProgressColor;
                    break;
                  case 'Reclamado':
                    color = AppTheme.resolvedColor;
                    break;
                  default:
                    color = Colors.grey;
                }
                
                return _buildStatusItem(
                  '${status.name} ${status.isFound ? '(Encontrado)' : '(Perdido)'}',
                  status.count.toString(),
                  color,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    if (_stats!.recentActivity.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No recent activity'),
          ),
        ),
      );
    }
    
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _stats!.recentActivity.length,
        itemBuilder: (context, index) {
          final activity = _stats!.recentActivity[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Text(
                HelperFunctions.getInitials(activity.fullName),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              _getActivityDescription(activity),
              style: TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              HelperFunctions.formatRelativeTime(activity.createdAt),
              style: TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  String _getActivityDescription(ActivityLog activity) {
    String entityType = activity.entityType;
    switch (activity.action) {
      case 'update_user_role':
        return '${activity.fullName} updated role for a user';
      case 'update_problem_status':
        return '${activity.fullName} updated status of a problem';
      case 'update_lostitem_status':
        return '${activity.fullName} updated status of a lost item';
      default:
        return '${activity.fullName} performed action on $entityType';
    }
  }
}