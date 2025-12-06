import 'package:flutter/material.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../config/app_routes.dart';
import '../services/map_service.dart';
import '../models/map_data_model.dart';
import '../widgets/campus_map_widget.dart';
import '../widgets/location_detail_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapService _mapService = MapService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  List<MapLocationData> _locationData = [];
  int? _selectedLocationId;
  LocationDetailData? _locationDetail;
  bool _viewProblems = true; // Toggle between problems and lost items
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _viewProblems = _tabController.index == 0;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationDetail = null;
    });

    try {
      // Load user data
      _currentUser = await _authService.getStoredUser();

      // Load map overview data
      final response = await _mapService.getMapOverview();
      if (response.success && response.data != null) {
        setState(() {
          _locationData = response.data!;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load map data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocationDetail(int locationId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedLocationId = locationId;
    });

    try {
      // Load problems for this location
      final problemsResponse = await _mapService.getProblemsByLocation(locationId);
      
      // Load lost items for this location
      final lostItemsResponse = await _mapService.getLostItemsByLocation(locationId);
      
      if (problemsResponse.success && lostItemsResponse.success) {
        setState(() {
          // Combine the location data, problems, and lost items
          _locationDetail = LocationDetailData(
            location: problemsResponse.data!.location,
            problems: problemsResponse.data!.problems,
            lostItems: lostItemsResponse.data!.lostItems,
          );
        });
      } else {
        setState(() {
          _errorMessage = problemsResponse.success 
              ? lostItemsResponse.message 
              : problemsResponse.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load location details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onLocationSelected(int locationId) {
    if (_selectedLocationId != locationId) {
      _loadLocationDetail(locationId);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedLocationId = null;
      _locationDetail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Mapa',
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
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _selectedLocationId == null
                ? _buildMapView()
                : _buildLocationDetailView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Icon(Icons.warning),
            text: 'Problemas',
          ),
          Tab(
            icon: Icon(Icons.search),
            text: 'Objetos Perdidos',
          ),
        ],
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMapView() {
    if (_locationData.isEmpty) {
      return Center(
        child: Text('No data available for the map.'),
      );
    }

    return CampusMapWidget(
      locationData: _locationData,
      viewProblems: _viewProblems,
      onLocationSelected: _onLocationSelected,
    );
  }

  Widget _buildLocationDetailView() {
    if (_locationDetail == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return LocationDetailWidget(
      locationDetail: _locationDetail!,
      viewProblems: _viewProblems,
      onBackPressed: _clearSelection,
      onProblemTap: (problemId) {
        Navigator.pushNamed(
          context,
          AppRoutes.problemDetail,
          arguments: {'problemId': problemId},
        );
      },
      onLostItemTap: (itemId) {
        Navigator.pushNamed(
          context,
          AppRoutes.lostItemDetail,
          arguments: {'itemId': itemId},
        );
      },
    );
  }
}