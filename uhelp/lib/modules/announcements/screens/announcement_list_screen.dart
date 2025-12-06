// lib/modules/announcements/screens/announcement_list_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/pagination_model.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import 'create_announcement_screen.dart';
import '../../../config/app_routes.dart';
import '../../../config/api_config.dart';
import 'package:timeago/timeago.dart' as timeago;

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({Key? key}) : super(key: key);

  @override
  _AnnouncementListScreenState createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  User? _currentUser;
  
  PaginatedData<Announcement>? _paginatedAnnouncements;
  bool _activeOnly = true;
  
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
      _loadMoreAnnouncements();
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
      
      // Load announcements
      await _loadAnnouncements();
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

  Future<void> _loadAnnouncements() async {
    try {
      final response = await _announcementService.getAnnouncements(
        activeOnly: _activeOnly,
        page: _currentPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _paginatedAnnouncements = response.data;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load announcements: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreAnnouncements() async {
    if (_isLoadingMore || _paginatedAnnouncements == null || !_paginatedAnnouncements!.hasNextPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _announcementService.getAnnouncements(
        activeOnly: _activeOnly,
        page: nextPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _currentPage = nextPage;
          
          // Append new data to existing list
          final updatedData = [
            ..._paginatedAnnouncements!.data,
            ...response.data!.data,
          ];
          
          _paginatedAnnouncements = PaginatedData<Announcement>(
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
      print('Error loading more announcements: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _toggleFilter() {
    setState(() {
      _activeOnly = !_activeOnly;
      _currentPage = 1;
    });
    _loadAnnouncements();
  }

  Future<void> _navigateToCreateAnnouncement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAnnouncementScreen(),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToEditAnnouncement(int announcementId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAnnouncementScreen(
          announcementId: announcementId,
        ),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteAnnouncement(int announcementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Announcement'),
        content: Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final response = await _announcementService.deleteAnnouncement(announcementId);
        
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Announcement deleted successfully')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.message}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting announcement: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreateAnnouncement = _currentUser?.isStaffOrAdmin ?? false;
    
    return BaseScreen(
      title: 'Anuncios',
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
      floatingActionButton: canCreateAnnouncement
          ? FloatingActionButton(
              onPressed: _navigateToCreateAnnouncement,
              child: Icon(Icons.add),
            )
          : null,
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
                  'Filtrar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Activos'),
                  selected: _activeOnly,
                  onSelected: (selected) {
                    _toggleFilter();
                  },
                ),
              ],
            ),
          ),
          
          // Announcements list
          Expanded(
            child: _paginatedAnnouncements?.data.isEmpty ?? true
                ? Center(
                    child: Text('No announcements found.'),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _currentPage = 1;
                      await _loadAnnouncements();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: (_paginatedAnnouncements?.data.length ?? 0) + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == (_paginatedAnnouncements?.data.length ?? 0)) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final announcement = _paginatedAnnouncements!.data[index];
                        return _buildAnnouncementCard(announcement);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final bool isExpired = announcement.endDate != null && 
                           announcement.endDate!.isBefore(DateTime.now());
    final bool isUserOwner = _currentUser?.id == announcement.userId;
    final bool isAdmin = _currentUser?.isStaffOrAdmin ?? false;
    final bool canEdit = isAdmin || isUserOwner;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: isExpired ? Colors.grey[100] : Colors.white,
      clipBehavior: Clip.antiAlias, // Important for image
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: announcement.isActive ? Colors.blue[50] : Colors.grey[200],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: announcement.isActive ? Colors.blue : Colors.grey,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canEdit)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditAnnouncement(announcement.id);
                      } else if (value == 'delete') {
                        _deleteAnnouncement(announcement.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Image if available
          if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              child: Image.network(
                '${ApiConfig.uploadBaseUrl}/announcements/${announcement.imageUrl}',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(announcement.content),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Publicado por ${announcement.creatorName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Publicado ${timeago.format(announcement.createdAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (announcement.startDate != announcement.createdAt) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'Active from ${_formatDate(announcement.startDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (announcement.endDate != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 16,
                        color: isExpired ? Colors.red : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Expires on ${_formatDate(announcement.endDate!)}',
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}