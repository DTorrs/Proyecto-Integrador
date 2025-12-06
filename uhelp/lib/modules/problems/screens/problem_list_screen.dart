import 'package:flutter/material.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/item_card.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/pagination_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/status_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../models/problem_model.dart';
import '../services/problem_service.dart';
import '../../../config/app_routes.dart';

class ProblemListScreen extends StatefulWidget {
  const ProblemListScreen({Key? key}) : super(key: key);

  @override
  _ProblemListScreenState createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends State<ProblemListScreen> {
  final ProblemService _problemService = ProblemService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  User? _currentUser;
  
  PaginatedData<Problem>? _paginatedProblems;
  List<Category> _categories = [];
  List<Status> _statuses = [];
  
  int? _selectedCategoryId;
  int? _selectedStatusId;
  String _sortBy = 'newest';
  String _selectedSortLabel = 'Nuevo';
  
  // Labels para mostrar en los botones
  String _selectedCategoryLabel = 'Todas las categorías';
  String _selectedStatusLabel = 'Todos los estados';
  
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
      _loadMoreProblems();
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

      // Load categories and statuses
      final categoriesResponse = await _problemService.getCategories();
      if (categoriesResponse.success && categoriesResponse.data != null) {
        _categories = categoriesResponse.data!;
      }

      final statusesResponse = await _problemService.getStatuses();
      if (statusesResponse.success && statusesResponse.data != null) {
        _statuses = statusesResponse.data!;
      }
      
      // Load problems
      await _loadProblems();
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

  Future<void> _loadProblems() async {
    try {
      final response = await _problemService.getProblems(
        categoryId: _selectedCategoryId,
        statusId: _selectedStatusId,
        sortBy: _sortBy,
        page: _currentPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _paginatedProblems = response.data;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load problems: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreProblems() async {
    if (_isLoadingMore || _paginatedProblems == null || !_paginatedProblems!.hasNextPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _problemService.getProblems(
        categoryId: _selectedCategoryId,
        statusId: _selectedStatusId,
        sortBy: _sortBy,
        page: nextPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _currentPage = nextPage;
          
          // Append new data to existing list
          final updatedData = [
            ..._paginatedProblems!.data,
            ...response.data!.data,
          ];
          
          _paginatedProblems = PaginatedData<Problem>(
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
      print('Error loading more problems: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    _currentPage = 1;
    _loadProblems();
  }

  Future<void> _onVote(int problemId, int index) async {
    try {
      final response = await _problemService.voteProblem(problemId);
      if (response.success && response.data != null) {
        setState(() {
          // Update the problem in the list with the new vote count
          final problems = _paginatedProblems?.data.toList() ?? [];
          if (index < problems.length) {
            problems[index] = Problem(
              id: problems[index].id,
              title: problems[index].title,
              description: problems[index].description,
              userId: problems[index].userId,
              username: problems[index].username,
              reporterName: problems[index].reporterName,
              locationId: problems[index].locationId,
              locationCode: problems[index].locationCode,
              locationName: problems[index].locationName,
              specificLocation: problems[index].specificLocation,
              categoryId: problems[index].categoryId,
              categoryName: problems[index].categoryName,
              statusId: problems[index].statusId,
              statusName: problems[index].statusName,
              imageUrl: problems[index].imageUrl,
              createdAt: problems[index].createdAt,
              updatedAt: problems[index].updatedAt,
              voteCount: response.data!['voteCount'] ?? problems[index].voteCount,
              userVoted: response.data!['userVoted'] ?? !problems[index].userVoted,
              comments: problems[index].comments,
            );
          }
          
          if (_paginatedProblems != null) {
            _paginatedProblems = PaginatedData<Problem>(
              page: _paginatedProblems!.page,
              pageSize: _paginatedProblems!.pageSize,
              total: _paginatedProblems!.total,
              totalPages: _paginatedProblems!.totalPages,
              data: problems,
              hasNextPage: _paginatedProblems!.hasNextPage,
              hasPreviousPage: _paginatedProblems!.hasPreviousPage,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to vote: ${e.toString()}')),
      );
    }
  }

  void _showCategorySelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 16),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Text(
                  'Seleccionar Categoría',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // All categories option
                      _buildSelectionTile(
                        title: 'Todas las categorías',
                        isSelected: _selectedCategoryId == null,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = null;
                            _selectedCategoryLabel = 'Todas las categorías';
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                      ),
                      // Category list
                      ..._categories.map((category) {
                        return _buildSelectionTile(
                          title: category.name,
                          isSelected: _selectedCategoryId == category.id,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category.id;
                              _selectedCategoryLabel = category.name;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 16),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Text(
                  'Seleccionar Estado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // All statuses option
                      _buildSelectionTile(
                        title: 'Todos los estados',
                        isSelected: _selectedStatusId == null,
                        onTap: () {
                          setState(() {
                            _selectedStatusId = null;
                            _selectedStatusLabel = 'Todos los estados';
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                      ),
                      // Status list
                      ..._statuses.map((status) {
                        return _buildSelectionTile(
                          title: status.name,
                          isSelected: _selectedStatusId == status.id,
                          onTap: () {
                            setState(() {
                              _selectedStatusId = status.id;
                              _selectedStatusLabel = status.name;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 16),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Text(
                  'Ordenar por',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSelectionTile(
                title: 'Nuevo',
                isSelected: _sortBy == 'newest',
                onTap: () {
                  setState(() {
                    _sortBy = 'newest';
                    _selectedSortLabel = 'Nuevo';
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
                leadingIcon: Icons.arrow_downward,
              ),
              _buildSelectionTile(
                title: 'Antiguo',
                isSelected: _sortBy == 'oldest',
                onTap: () {
                  setState(() {
                    _sortBy = 'oldest';
                    _selectedSortLabel = 'Antiguo';
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
                leadingIcon: Icons.arrow_upward,
              ),
              _buildSelectionTile(
                title: 'Más votado',
                isSelected: _sortBy == 'votes',
                onTap: () {
                  setState(() {
                    _sortBy = 'votes';
                    _selectedSortLabel = 'Más votado';
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
                leadingIcon: Icons.thumb_up,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSelectionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? leadingIcon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
                size: 20,
              ),
              SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Problemas: Reportes',
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
      useScrollView: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createProblem)
              .then((_) => _loadProblems());
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _paginatedProblems?.data.isEmpty ?? true
                ? Center(
                    child: Text('No existen reportes.'),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _currentPage = 1;
                      await _loadProblems();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: (_paginatedProblems?.data.length ?? 0) + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == (_paginatedProblems?.data.length ?? 0)) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final problem = _paginatedProblems!.data[index];
                        return ItemCard(
                          id: problem.id,
                          title: problem.title,
                          description: problem.description,
                          imageUrl: problem.imageUrl,
                          location: problem.locationDisplay,
                          status: problem.statusName,
                          statusId: problem.statusId,
                          createdAt: problem.createdAt,
                          username: problem.username,
                          type: ItemType.problem,
                          voteCount: problem.voteCount,
                          userVoted: problem.userVoted,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.problemDetail,
                              arguments: {'problemId': problem.id},
                            ).then((_) => _loadProblems());
                          },
                          onVote: () => _onVote(problem.id, index),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    label: 'Categoría',
                    value: _selectedCategoryLabel,
                    onPressed: _showCategorySelectionDialog,
                    icon: Icons.category,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton(
                    label: 'Estado',
                    value: _selectedStatusLabel,
                    onPressed: _showStatusSelectionDialog,
                    icon: Icons.flag,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildFilterButton(
              label: 'Ordenar por',
              value: _selectedSortLabel,
              onPressed: _showSortOptionsDialog,
              isFullWidth: true,
              icon: _getSortIcon(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSortIcon() {
    switch (_sortBy) {
      case 'newest':
        return Icons.arrow_downward;
      case 'oldest':
        return Icons.arrow_upward;
      case 'votes':
        return Icons.thumb_up;
      default:
        return Icons.sort;
    }
  }

  Widget _buildFilterButton({
    required String label,
    required String value,
    required VoidCallback onPressed,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}