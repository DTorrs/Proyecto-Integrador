import 'package:flutter/material.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/item_card.dart';
import '../../../core/models/pagination_model.dart';
import '../../../core/models/status_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../models/lost_item_model.dart';
import '../services/lost_item_service.dart';
import '../../map/services/map_service.dart';
import '../../../core/models/location_model.dart';
import '../../../config/app_routes.dart';

class LostItemListScreen extends StatefulWidget {
  const LostItemListScreen({Key? key}) : super(key: key);

  @override
  _LostItemListScreenState createState() => _LostItemListScreenState();
}

class _LostItemListScreenState extends State<LostItemListScreen> {
  final LostItemService _lostItemService = LostItemService();
  final MapService _mapService = MapService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  User? _currentUser;
  
  PaginatedData<LostItem>? _paginatedItems;
  List<Status> _statuses = [];
  List<Location> _locations = [];
  
  int? _selectedStatusId;
  int? _selectedLocationId;
  bool? _isFound;
  
  // Labels para mostrar en los botones
  String _selectedStatusLabel = 'Todos los estados';
  String _selectedLocationLabel = 'Todas las ubicaciones';
  String _selectedTypeLabel = 'Todos';
  
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
      _loadMoreItems();
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

      // Load statuses
      final statusesResponse = await _lostItemService.getStatuses();
      if (statusesResponse.success && statusesResponse.data != null) {
        _statuses = statusesResponse.data!;
      }

      // Load locations
      final locationsResponse = await _mapService.getLocations();
      if (locationsResponse.success && locationsResponse.data != null) {
        _locations = locationsResponse.data!;
      }
      
      // Load lost items
      await _loadItems();
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

  Future<void> _loadItems() async {
    try {
      final response = await _lostItemService.getLostItems(
        isFound: _isFound,
        statusId: _selectedStatusId,
        locationId: _selectedLocationId,
        page: _currentPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _paginatedItems = response.data;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load items: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || _paginatedItems == null || !_paginatedItems!.hasNextPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _lostItemService.getLostItems(
        isFound: _isFound,
        statusId: _selectedStatusId,
        locationId: _selectedLocationId,
        page: nextPage,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _currentPage = nextPage;
          
          // Append new data to existing list
          final updatedData = [
            ..._paginatedItems!.data,
            ...response.data!.data,
          ];
          
          _paginatedItems = PaginatedData<LostItem>(
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
      print('Error loading more items: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    _currentPage = 1;
    _loadItems();
  }

  void _showTypeSelectionDialog() {
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
                  'Seleccionar Tipo',
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
                      // All types option
                      _buildSelectionTile(
                        title: 'Todos',
                        isSelected: _isFound == null,
                        onTap: () {
                          setState(() {
                            _isFound = null;
                            _selectedTypeLabel = 'Todos';
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                      ),
                      // Lost option
                      _buildSelectionTile(
                        title: 'Perdidos',
                        isSelected: _isFound == false,
                        onTap: () {
                          setState(() {
                            _isFound = false;
                            _selectedTypeLabel = 'Perdidos';
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                      ),
                      // Found option
                      _buildSelectionTile(
                        title: 'Encontrados',
                        isSelected: _isFound == true,
                        onTap: () {
                          setState(() {
                            _isFound = true;
                            _selectedTypeLabel = 'Encontrados';
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                      ),
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

  void _showLocationSelectionDialog() {
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
                  'Seleccionar Ubicación',
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
                      // All locations option
                      _buildSelectionTile(
                        title: 'Todas las ubicaciones',
                        isSelected: _selectedLocationId == null,
                        onTap: () {
                          setState(() {
                            _selectedLocationId = null;
                            _selectedLocationLabel = 'Todas las ubicaciones';
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                      ),
                      // Location list
                      ..._locations.map((location) {
                        return _buildSelectionTile(
                          title: '${location.code}: ${location.name}',
                          isSelected: _selectedLocationId == location.id,
                          onTap: () {
                            setState(() {
                              _selectedLocationId = location.id;
                              _selectedLocationLabel = '${location.code}: ${location.name}';
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
      title: 'Objetos Perdidos',
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
          Navigator.pushNamed(context, AppRoutes.createLostItem)
              .then((_) => _loadItems());
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _paginatedItems?.data.isEmpty ?? true
                ? Center(
                    child: Text('No existen objetos perdidos.'),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _currentPage = 1;
                      await _loadItems();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: (_paginatedItems?.data.length ?? 0) + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == (_paginatedItems?.data.length ?? 0)) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final item = _paginatedItems!.data[index];
                        return ItemCard(
                          id: item.id,
                          title: item.title,
                          description: item.description,
                          imageUrl: item.imageUrl,
                          location: item.locationDisplay,
                          status: item.statusName,
                          statusId: item.statusId,
                          createdAt: item.createdAt,
                          username: item.username,
                          type: ItemType.lostItem,
                          isFound: item.isFound,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.lostItemDetail,
                              arguments: {'itemId': item.id},
                            ).then((_) => _loadItems());
                          },
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
                    label: 'Tipo',
                    value: _selectedTypeLabel,
                    onPressed: _showTypeSelectionDialog,
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
              label: 'Ubicación',
              value: _selectedLocationLabel,
              onPressed: _showLocationSelectionDialog,
              isFullWidth: true,
              icon: Icons.location_on,
            ),
          ],
        ),
      ),
    );
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