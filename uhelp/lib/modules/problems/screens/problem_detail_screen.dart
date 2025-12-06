import 'package:flutter/material.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/comment_widget.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../services/problem_service.dart';
import '../models/problem_model.dart';

class ProblemDetailScreen extends StatefulWidget {
  final int problemId;

  const ProblemDetailScreen({
    Key? key,
    required this.problemId,
  }) : super(key: key);

  @override
  _ProblemDetailScreenState createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  final ProblemService _problemService = ProblemService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  Problem? _problem;
  User? _currentUser;
  bool _isAdmin = false;
  bool _isCommenting = false;

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
      _isAdmin = _currentUser?.isStaffOrAdmin ?? false;

      // Load problem details
      final response = await _problemService.getProblemById(widget.problemId);
      if (response.success && response.data != null) {
        setState(() {
          _problem = response.data;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load problem details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVote() async {
    if (_problem == null || _currentUser == null) return;

    try {
      final response = await _problemService.voteProblem(_problem!.id);
      if (response.success && response.data != null) {
        setState(() {
          _problem = Problem(
            id: _problem!.id,
            title: _problem!.title,
            description: _problem!.description,
            userId: _problem!.userId,
            username: _problem!.username,
            reporterName: _problem!.reporterName,
            locationId: _problem!.locationId,
            locationCode: _problem!.locationCode,
            locationName: _problem!.locationName,
            specificLocation: _problem!.specificLocation,
            categoryId: _problem!.categoryId,
            categoryName: _problem!.categoryName,
            statusId: _problem!.statusId,
            statusName: _problem!.statusName,
            imageUrl: _problem!.imageUrl,
            createdAt: _problem!.createdAt,
            updatedAt: _problem!.updatedAt,
            voteCount: response.data!['voteCount'] ?? _problem!.voteCount,
            userVoted: response.data!['userVoted'] ?? !_problem!.userVoted,
            comments: _problem!.comments,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to vote: ${e.toString()}')),
      );
    }
  }

  Future<void> _addComment(String comment) async {
    if (_problem == null || _currentUser == null) return;

    setState(() {
      _isCommenting = true;
    });

    try {
      final response = await _problemService.addComment(_problem!.id, comment);
      if (response.success && response.data != null) {
        final updatedComments = [..._problem!.comments, response.data!];
        setState(() {
          _problem = Problem(
            id: _problem!.id,
            title: _problem!.title,
            description: _problem!.description,
            userId: _problem!.userId,
            username: _problem!.username,
            reporterName: _problem!.reporterName,
            locationId: _problem!.locationId,
            locationCode: _problem!.locationCode,
            locationName: _problem!.locationName,
            specificLocation: _problem!.specificLocation,
            categoryId: _problem!.categoryId,
            categoryName: _problem!.categoryName,
            statusId: _problem!.statusId,
            statusName: _problem!.statusName,
            imageUrl: _problem!.imageUrl,
            createdAt: _problem!.createdAt,
            updatedAt: _problem!.updatedAt,
            voteCount: _problem!.voteCount,
            userVoted: _problem!.userVoted,
            comments: updatedComments,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isCommenting = false;
      });
    }
  }

  Future<void> _deleteComment(int commentId) async {
    if (_problem == null) return;

    try {
      final response = await _problemService.deleteComment(_problem!.id, commentId);
      if (response.success) {
        setState(() {
          _problem = Problem(
            id: _problem!.id,
            title: _problem!.title,
            description: _problem!.description,
            userId: _problem!.userId,
            username: _problem!.username,
            reporterName: _problem!.reporterName,
            locationId: _problem!.locationId,
            locationCode: _problem!.locationCode,
            locationName: _problem!.locationName,
            specificLocation: _problem!.specificLocation,
            categoryId: _problem!.categoryId,
            categoryName: _problem!.categoryName,
            statusId: _problem!.statusId,
            statusName: _problem!.statusName,
            imageUrl: _problem!.imageUrl,
            createdAt: _problem!.createdAt,
            updatedAt: _problem!.updatedAt,
            voteCount: _problem!.voteCount,
            userVoted: _problem!.userVoted,
            comments: _problem!.comments.where((c) => c.id != commentId).toList(),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete comment: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateStatus(int statusId) async {
    if (_problem == null || !_isAdmin) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _problemService.updateStatus(_problem!.id, statusId);
      if (response.success && response.data != null) {
        setState(() {
          _problem = response.data;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProblem() async {
    if (_problem == null) return;

    final confirmationMessage = '¿Estás seguro de que quieres eliminar este reporte de problema?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar problema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(confirmationMessage),
            SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _problemService.deleteProblem(_problem!.id);
        
        setState(() {
          _isLoading = false;
        });
        
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El reporte de problema ha sido eliminado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.message}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el problema: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Detalles del problema',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadData,
      // CAMBIO IMPORTANTE: Siempre mostramos el botón de eliminar
      actions: [
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: _deleteProblem,
        ),
      ],
      body: _problem == null
          ? Container()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_problem?.imageUrl != null && _problem!.imageUrl!.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${ApiConfig.uploadBaseUrl}/problems/${_problem!.imageUrl}',
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
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('No se pudo cargar la imagen',
                                      style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        _buildStatusBadge(),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            _problem!.userVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: _problem!.userVoted ? AppTheme.primaryColor : Colors.grey[600],
                          ),
                          onPressed: _toggleVote,
                        ),
                        Text(
                          _problem!.voteCount.toString(),
                          style: TextStyle(
                            color: _problem!.userVoted ? AppTheme.primaryColor : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _problem?.title ?? 'No Title',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _problem?.description ?? 'No Description',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          _problem?.locationDisplay ?? 'Unknown Location',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _problem?.specificLocation ?? 'No specific location',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          _problem?.categoryName ?? 'Unknown Category',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'Reportado por ${_problem?.reporterName ?? 'Unknown'} (@${_problem?.username ?? 'Unknown'})',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
               
                    SizedBox(height: 16),
                    
                    if (_isAdmin) _buildStatusUpdateSection(),
                    SizedBox(height: 24),
                    CommentSection(
                      comments: _problem!.comments.map((c) => Comment(
                        id: c.id,
                        comment: c.comment,
                        username: c.username,
                        fullName: c.fullName,
                        createdAt: c.createdAt,
                        isOwner: c.userId == _currentUser?.id || _currentUser?.isAdmin == true,
                      )).toList(),
                      onAddComment: _addComment,
                      onDeleteComment: _deleteComment,
                      isLoading: _isCommenting,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge() {
    if (_problem == null) return Container();

    Color color;
    switch (_problem!.statusId) {
      case 1: // Pending
        color = AppTheme.pendingColor;
        break;
      case 2: // In Progress
        color = AppTheme.inProgressColor;
        break;
      case 3: // Resolved
        color = AppTheme.resolvedColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        _problem?.statusName ?? 'Unknown',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

 Widget _buildStatusUpdateSection() {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: EdgeInsets.all(12), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10), // Slightly reduced spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusButton(1, 'Pendiente', AppTheme.pendingColor),
              _buildStatusButton(2, 'En Progreso', AppTheme.inProgressColor),
              _buildStatusButton(3, 'Resuelto', AppTheme.resolvedColor),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatusButton(int statusId, String label, Color color) {
  final isSelected = _problem?.statusId == statusId;
  return ElevatedButton(
    onPressed: isSelected == true ? null : () => _updateStatus(statusId),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12, // Smaller text
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: isSelected == true ? Colors.grey : color,
      disabledBackgroundColor: color.withOpacity(0.7),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Smaller padding
      minimumSize: Size(85, 30), // Smaller button size
    ),
  );
}
}