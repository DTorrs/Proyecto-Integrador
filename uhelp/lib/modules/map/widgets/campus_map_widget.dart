import 'package:flutter/material.dart';
import '../models/map_data_model.dart';
import '../../../config/app_theme.dart';

class CampusMapWidget extends StatelessWidget {
  final List<MapLocationData> locationData;
  final bool viewProblems;
  final Function(int) onLocationSelected;

  const CampusMapWidget({
    Key? key,
    required this.locationData,
    required this.viewProblems,
    required this.onLocationSelected,
  }) : super(key: key);

  // Optional map for manual positioning of specific buildings
  // If a building code is not in this map, it will use the default positioning
  Map<String, Offset> getCustomPositions(double width, double height) {
    return {
      // Uncomment and adjust these as needed
      'A': Offset(0.002 * width, 0.515 * height),
      'B': Offset(0.065 * width, 0.545 * height),
      'C': Offset(0.22 * width, 0.535 * height),
      'D': Offset(0.38 * width, 0.440 * height),
      'E': Offset(0.616 * width, 0.415 * height),
      'F': Offset(0.725 * width, 0.445 * height),
      'G': Offset(0.85 * width, 0.46 * height),
      'H': Offset(0.87 * width, 0.41 * height),
      'I': Offset(0.78 * width, 0.3 * height),
      'J': Offset(0.375 * width, 0.56 * height),
      'K': Offset(0.41 * width, 0.22 * height),
      'L': Offset(0.94 * width, 0.25 * height),
      
      
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final customPositions = getCustomPositions(screenSize.width, screenSize.height);

    return Stack(
      children: [
        // Campus map background image
        Container(
          width: double.infinity,
          height: double.infinity,
          child: Image.asset(
            'lib/assets/plano.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading map image: $error');
              return Center(child: Text('Error loading map image'));
            },
          ),
        ),
        
        // Overlay the location markers on the map
        ...locationData
            .where((location) => location.code != 'OTHER') // Skip "OTHER" location
            .map((location) {
              // Check if this location has a custom position defined
              if (customPositions.containsKey(location.code)) {
                return _buildLocationMarker(
                  context, 
                  location, 
                  customPositions[location.code]!.dx, 
                  customPositions[location.code]!.dy,
                  useCustomPosition: true
                );
              } else {
                // Use default positioning based on ID
                final double left = (location.id * 30) % (MediaQuery.of(context).size.width - 60);
                final double top = (location.id * 20) % (MediaQuery.of(context).size.height - 120);
                return _buildLocationMarker(context, location, left, top);
              }
            })
            .toList(),
            
        // Instructions at the bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'UPB Bucaramanga',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: viewProblems ? AppTheme.primaryColor : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(viewProblems ? 'Problemas' : 'Objetos Perdidos'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Click en edificio para ver detalles.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMarker(
    BuildContext context, 
    MapLocationData location, 
    double left, 
    double top, 
    {bool useCustomPosition = false}
  ) {
    final int count = viewProblems ? location.activeProblems : location.activeItems;
    final Color markerColor = viewProblems ? AppTheme.primaryColor : Colors.orange;
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => onLocationSelected(location.id),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: count > 0 ? markerColor : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Text(
                location.code,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: markerColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}