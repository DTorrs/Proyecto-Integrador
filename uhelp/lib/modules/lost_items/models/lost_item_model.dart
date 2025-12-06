import '../../../core/models/user_model.dart';

class LostItem {
  final int id;
  final String title;
  final String description;
  final int userId;
  final String username;
  final String reporterName;
  final int locationId;
  final String locationCode;
  final String locationName;
  final String specificLocation;
  final bool isFound;
  final int statusId;
  final String statusName;
  final String? imageUrl;
  final String? idPhotoUrl;     // Nuevo campo para la foto de identificación
  final String? claimPhotoUrl;  // Nuevo campo para la foto de reclamación
  final String contactInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  LostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.username,
    required this.reporterName,
    required this.locationId,
    required this.locationCode,
    required this.locationName,
    required this.specificLocation,
    required this.isFound,
    required this.statusId,
    required this.statusName,
    this.imageUrl,
    this.idPhotoUrl,      // Nuevo campo
    this.claimPhotoUrl,   // Nuevo campo
    required this.contactInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostItem.fromJson(Map<String, dynamic> json) {
    print("LostItem.fromJson: $json");
    try {
      // Extract the nested "lostItem" object if it exists
      final itemData = json.containsKey('lostItem') ? json['lostItem'] : json;
      
      print("Extracted item data: $itemData");
      
      // Handle image URL properly
      String? imageUrl = itemData['image_url'];
      if (imageUrl != null) {
        // Clean up the URL if needed (remove any extra slashes or whitespace)
        imageUrl = imageUrl.trim();
        print("Image URL from API: $imageUrl");
      }
      
      // Extraer URLs de las fotos de reclamación
      String? idPhotoUrl = itemData['id_photo_url'];
      String? claimPhotoUrl = itemData['claim_photo_url'];
      
      // Manejo de posibles valores nulos o tipos incorrectos
      int id = 0;
      if (itemData['id'] != null) {
        id = itemData['id'] is int ? itemData['id'] : int.tryParse(itemData['id'].toString()) ?? 0;
      }
      
      int userId = 0;
      if (itemData['user_id'] != null) {
        userId = itemData['user_id'] is int ? itemData['user_id'] : int.tryParse(itemData['user_id'].toString()) ?? 0;
      }
      
      int locationId = 0;
      if (itemData['location_id'] != null) {
        locationId = itemData['location_id'] is int ? itemData['location_id'] : int.tryParse(itemData['location_id'].toString()) ?? 0;
      }
      
      int statusId = 0;
      if (itemData['status_id'] != null) {
        statusId = itemData['status_id'] is int ? itemData['status_id'] : int.tryParse(itemData['status_id'].toString()) ?? 0;
      }
      
      // Handle is_found field which could be int (0/1) or boolean
      bool isFound = false;
      if (itemData['is_found'] != null) {
        if (itemData['is_found'] is bool) {
          isFound = itemData['is_found'];
        } else if (itemData['is_found'] is int) {
          isFound = itemData['is_found'] == 1;
        } else if (itemData['is_found'] is String) {
          isFound = itemData['is_found'] == '1' || itemData['is_found'].toLowerCase() == 'true';
        }
      }
      
      final title = itemData['title'] ?? '';
      print("Title: $title");
      
      final result = LostItem(
        id: id,
        title: title,
        description: itemData['description'] ?? '',
        userId: userId,
        username: itemData['username'] ?? '',
        reporterName: itemData['reporter_name'] ?? itemData['username'] ?? '',
        locationId: locationId,
        locationCode: itemData['location_code'] ?? '',
        locationName: itemData['location_name'] ?? '',
        specificLocation: itemData['specific_location'] ?? '',
        isFound: isFound,
        statusId: statusId,
        statusName: itemData['status_name'] ?? '',
        imageUrl: imageUrl,
        idPhotoUrl: idPhotoUrl,      // Agregamos los nuevos campos
        claimPhotoUrl: claimPhotoUrl,// Agregamos los nuevos campos
        contactInfo: itemData['contact_info'] ?? '',
        createdAt: itemData['created_at'] != null ? DateTime.parse(itemData['created_at']) : DateTime.now(),
        updatedAt: itemData['updated_at'] != null ? DateTime.parse(itemData['updated_at'] ?? itemData['created_at']) : DateTime.now(),
      );
      
      print("Created LostItem object with title: ${result.title}");
      return result;
    } catch (e) {
      print("Error parsing LostItem: $e");
      // Print the stacktrace for more detailed debugging
      print(StackTrace.current);
      
      // Devolver un objeto LostItem mínimo válido en caso de error
      return LostItem(
        id: 0,
        title: 'Error',
        description: 'Error parsing lost item',
        userId: 0,
        username: 'unknown',
        reporterName: 'unknown',
        locationId: 0,
        locationCode: '',
        locationName: '',
        specificLocation: '',
        isFound: false,
        statusId: 0,
        statusName: '',
        contactInfo: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  String get locationDisplay => '$locationCode: $locationName';

  String get typeDisplay => isFound ? 'Encontrado' : 'Perdido';
  
  // Nuevos getters útiles
  bool get isClaimed => statusId == 3;
  bool get hasClaimPhotos => idPhotoUrl != null && claimPhotoUrl != null;
}