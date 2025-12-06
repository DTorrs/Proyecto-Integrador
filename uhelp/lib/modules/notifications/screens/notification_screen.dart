// lib/modules/notifications/screens/notification_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/pagination_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../../../config/app_routes.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  User? _currentUser;
  
  PaginatedData<UserNotification>? _paginatedNotifications;  // Updated type
  bool _unreadOnly = false;
  
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      // Load user data
      _currentUser = await _authService.getStoredUser();
      
      // Load notifications
      await _loadNotifications();
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

  Future<void> _loadNotifications() async {
    try {
      final response = await _notificationService.getNotifications(
        unreadOnly: _unreadOnly,
        page: _currentPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _paginatedNotifications = response.data;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || _paginatedNotifications == null || !_paginatedNotifications!.hasNextPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _notificationService.getNotifications(
        unreadOnly: _unreadOnly,
        page: nextPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _currentPage = nextPage;
          
          // Append new data to existing list
          final updatedData = [
            ..._paginatedNotifications!.data,
            ...response.data!.data,
          ];
          
          _paginatedNotifications = PaginatedData<UserNotification>(  // Updated type
            page: response.data!.page,
            pageSize: response.data!.pageSize,
            total: response.data!.total,
            totalPages: response.data!.totalPages,
            data: updatedData,
            hasNextPage: response.data!.hasNextPage,
            hasPreviousPage: response.data!.hasPreviousPage,
          );
        });
      }
    } catch (e) {
      print('Error loading more notifications: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final response = await _notificationService.markAsRead(notificationId);
      if (response.success) {
        setState(() {
          if (_paginatedNotifications != null) {
            final updatedNotifications = _paginatedNotifications!.data.map((notification) {
              if (notification.id == notificationId) {
                return UserNotification(  // Updated constructor
                  id: notification.id,
                  userId: notification.userId,
                  title: notification.title,
                  message: notification.message,
                  isRead: true,
                  relatedType: notification.relatedType,
                  relatedId: notification.relatedId,
                  createdAt: notification.createdAt,
                );
              }
              return notification;
            }).toList();
            
            _paginatedNotifications = PaginatedData<UserNotification>(  // Updated type
              page: _paginatedNotifications!.page,
              pageSize: _paginatedNotifications!.pageSize,
              total: _paginatedNotifications!.total,
              totalPages: _paginatedNotifications!.totalPages,
              data: updatedNotifications,
              hasNextPage: _paginatedNotifications!.hasNextPage,
              hasPreviousPage: _paginatedNotifications!.hasPreviousPage,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notification as read')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await _notificationService.markAllAsRead();
      if (response.success) {
        setState(() {
          if (_paginatedNotifications != null) {
            final updatedNotifications = _paginatedNotifications!.data.map((notification) {
              return UserNotification(  // Updated constructor
                id: notification.id,
                userId: notification.userId,
                title: notification.title,
                message: notification.message,
                isRead: true,
                relatedType: notification.relatedType,
                relatedId: notification.relatedId,
                createdAt: notification.createdAt,
              );
            }).toList();
            
            _paginatedNotifications = PaginatedData<UserNotification>(  // Updated type
              page: _paginatedNotifications!.page,
              pageSize: _paginatedNotifications!.pageSize,
              total: _paginatedNotifications!.total,
              totalPages: _paginatedNotifications!.totalPages,
              data: updatedNotifications,
              hasNextPage: _paginatedNotifications!.hasNextPage,
              hasPreviousPage: _paginatedNotifications!.hasPreviousPage,
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all notifications as read')),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final response = await _notificationService.deleteNotification(notificationId);
      if (response.success) {
        setState(() {
          if (_paginatedNotifications != null) {
            final updatedNotifications = _paginatedNotifications!.data
                .where((notification) => notification.id != notificationId)
                .toList();
            
            _paginatedNotifications = PaginatedData<UserNotification>(  // Updated type
              page: _paginatedNotifications!.page,
              pageSize: _paginatedNotifications!.pageSize,
              total: _paginatedNotifications!.total - 1,
              totalPages: (_paginatedNotifications!.total - 1) ~/ _paginatedNotifications!.pageSize + 1,
              data: updatedNotifications,
              hasNextPage: _paginatedNotifications!.hasNextPage,
              hasPreviousPage: _paginatedNotifications!.hasPreviousPage,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification')),
      );
    }
  }

  void _toggleFilter() {
    setState(() {
      _unreadOnly = !_unreadOnly;
      _currentPage = 1;
    });
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Notificaciones',
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
      actions: [
        if (_paginatedNotifications?.data.any((n) => !n.isRead) ?? false)
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
      ],
      useScrollView: false,
      body: Column(
        children: [
          // Filter toggle
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Filter:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Sin leer'),
                  selected: _unreadOnly,
                  onSelected: (selected) {
                    _toggleFilter();
                  },
                ),
              ],
            ),
          ),
          
          // Notifications list
          Expanded(
            child: _paginatedNotifications?.data.isEmpty ?? true
                ? Center(
                    child: Text('No notifications found.'),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _currentPage = 1;
                      await _loadNotifications();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(0),
                      itemCount: (_paginatedNotifications?.data.length ?? 0) + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == (_paginatedNotifications?.data.length ?? 0)) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final notification = _paginatedNotifications!.data[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(UserNotification notification) {  // Updated parameter type
    // Determine icon based on notification type
    IconData iconData;
    Color iconColor;
    
    switch (notification.relatedType) {
      case 'problem':
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'lost_item':
        iconData = Icons.search;
        iconColor = Colors.blue;
        break;
      case 'announcement':
        iconData = Icons.campaign;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key('notification_${notification.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: notification.isRead ? 1 : 3,
        color: notification.isRead ? Colors.white : Colors.blue[50],
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            
            // Navigate to related content if needed
            switch (notification.relatedType) {
              case 'problem':
                Navigator.pushNamed(
                  context,
                  AppRoutes.problemDetail,
                  arguments: {'problemId': notification.relatedId},
                );
                break;
              case 'lost_item':
                Navigator.pushNamed(
                  context,
                  AppRoutes.lostItemDetail,
                  arguments: {'itemId': notification.relatedId},
                );
                break;
              case 'announcement':
                Navigator.pushNamed(
                  context,
                  AppRoutes.announcements,
                );
                break;
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        timeago.format(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}