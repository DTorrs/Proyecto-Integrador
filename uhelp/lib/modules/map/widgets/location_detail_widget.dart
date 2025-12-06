import 'package:flutter/material.dart';
import '../models/map_data_model.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class LocationDetailWidget extends StatelessWidget {
  final LocationDetailData locationDetail;
  final bool viewProblems;
  final VoidCallback onBackPressed;
  final Function(int) onProblemTap;
  final Function(int) onLostItemTap;

  const LocationDetailWidget({
    Key? key,
    required this.locationDetail,
    required this.viewProblems,
    required this.onBackPressed,
    required this.onProblemTap,
    required this.onLostItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = viewProblems
        ? locationDetail.problems
        : locationDetail.lostItems;

    return Column(
      children: [
        // Header with location info and back button
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: onBackPressed,
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${locationDetail.location.code}: ${locationDetail.location.name}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    viewProblems
                        ? '${items.length} ${items.length == 1 ? 'problem' : 'problems'}'
                        : '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // List of items
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    viewProblems
                        ? 'No hay problemas reportados en esta ubicación.'
                        : 'No hay objetos perdidos ni encontrados en esta ubicación.',
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemCard(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, ItemSummary item) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (viewProblems) {
            onProblemTap(item.id);
          } else {
            onLostItemTap(item.id);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  child: Image.network(
                    // Corregimos la URL de la imagen
                    _buildImageUrl(item.imageUrl!, viewProblems),
                    fit: BoxFit.cover,
                    // Agregamos headers si son necesarios
                    headers: {'Cache-Control': 'max-age=0'},
                    // Mejoramos el errorBuilder para mostrar más información
                    errorBuilder: (context, error, stackTrace) {
                      final imgUrl = _buildImageUrl(item.imageUrl!, viewProblems);
                      print('Error cargando imagen: $error');
                      print('URL de la imagen: $imgUrl');
                      
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            SizedBox(height: 4),
                            Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusBadge(item),
                      if (!viewProblems) ...[
                        SizedBox(width: 8),
                        _buildTypeBadge(item),
                      ],
                      Spacer(),
                      Text(
                        timeago.format(item.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        item.username,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (viewProblems) ...[
                        Spacer(),
                        Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          item.voteCount.toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir la URL de la imagen correctamente
  String _buildImageUrl(String imageUrl, bool isProblems) {
    // Verificamos si la URL ya es completa (comienza con http o https)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    // Verificamos si la URL ya incluye la ruta completa
    if (imageUrl.contains('/problems/') || imageUrl.contains('/lostitems/')) {
      return '${ApiConfig.uploadBaseUrl}/$imageUrl';
    }
    
    // Construimos la URL con el formato correcto usando los nombres de directorio
    // que coinciden con los del servidor (en inglés)
    final category = isProblems ? 'problems' : 'lostitems';
    
    // Eliminamos cualquier '/' inicial para evitar rutas duplicadas
    final cleanImageUrl = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
    
    // Imprimir la URL para depuración
    print('Intentando cargar imagen desde: ${ApiConfig.uploadBaseUrl}/$category/$cleanImageUrl');
    
    return '${ApiConfig.uploadBaseUrl}/$category/$cleanImageUrl';
  }

  Widget _buildStatusBadge(ItemSummary item) {
    Color color;
    switch (item.statusId) {
      case 1: // Pending / Reported
        color = AppTheme.pendingColor;
        break;
      case 2: // In Progress / In D300
        color = AppTheme.inProgressColor;
        break;
      case 3: // Resolved / Claimed
        color = AppTheme.resolvedColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        item.statusName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ItemSummary item) {
    final color = item.isFound ? Colors.green : Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        item.isFound ? 'Encontrado' : 'Perdido',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}