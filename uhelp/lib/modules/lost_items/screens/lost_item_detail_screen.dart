import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../services/lost_item_service.dart';
import '../models/lost_item_model.dart';
import '../widgets/image_selector.dart';

class LostItemDetailScreen extends StatefulWidget {
  final int itemId;

  const LostItemDetailScreen({
    Key? key,
    required this.itemId,
  }) : super(key: key);

  @override
  _LostItemDetailScreenState createState() => _LostItemDetailScreenState();
}

class _LostItemDetailScreenState extends State<LostItemDetailScreen> {
  final LostItemService _lostItemService = LostItemService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  String? _errorMessage;
  LostItem? _item;
  User? _currentUser;
  bool _isAdmin = false;

  // Variables para las fotos de reclamación
  File? _idPhoto;
  File? _claimPhoto;
  bool _isUpdatingStatus = false;
  bool _showClaimSection = false;

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
      // Load user data with better logging
      _currentUser = await _authService.getStoredUser();
      _isAdmin = _currentUser?.isStaffOrAdmin ?? false;
      
      // DEPURACIÓN: Mostrar todo el objeto de usuario
      print("Usuario completo: ${_currentUser?.toJson()}");
      
      int userId = _currentUser?.id ?? 0;
      print("Current user loaded: ${_currentUser?.username}, ID: $userId, isAdmin: $_isAdmin");

      // Load item details
      print("Loading lost item with ID: ${widget.itemId}");
      final response = await _lostItemService.getLostItemById(widget.itemId);
      print("Item response: ${response.success} - ${response.message}");
      
      if (response.success && response.data != null) {
        // Safer logging with null checks
        print("Response data is not null");
        
        // Assign to local variable and then to state
        final loadedItem = response.data;
        
        // Using null-safe property access
        print("Title: ${loadedItem?.title}");
        print("ID: ${loadedItem?.id}");
        print("Image URL: ${loadedItem?.imageUrl ?? 'No image URL'}");
        print("Item owner userId: ${loadedItem?.userId}");
        print("Current userId: $userId");
        
        // DEPURACIÓN: Verificar tipo de datos de los IDs
        print("Tipo de userId del item: ${loadedItem?.userId.runtimeType}");
        print("Tipo de id del usuario: ${_currentUser?.id.runtimeType}");
        
        print("Can delete by ownership: ${loadedItem?.userId == userId}");
        print("Can delete by admin: $_isAdmin");
        
        setState(() {
          _item = loadedItem;
        });
        
        // Check state after update
        print("Item set in state: ${_item != null}");
        
        // DEPURACIÓN: Verificar métodos de propiedad después de establecer el estado
        print("isOwner(): ${_isOwner()}");
        print("canDelete(): ${_canDelete()}");
      } else {
        setState(() {
          _errorMessage = response.message;
        });
        print("Error loading item: $_errorMessage");
      }
    } catch (e) {
      print("Exception loading item details: $e");
      setState(() {
        _errorMessage = 'Failed to load item details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verificar si el usuario actual es propietario del item
  bool _isOwner() {
    // DEPURACIÓN: Mostramos información detallada para diagnosticar el problema
    print("VERIFICANDO PROPIEDAD:");
    print("_currentUser es nulo: ${_currentUser == null}");
    print("_item es nulo: ${_item == null}");
    
    if (_currentUser == null || _item == null) {
      print("Alguno de los objetos es nulo, retornando false");
      return false;
    }
    
    print("userId del item: ${_item!.userId}");
    print("id del usuario: ${_currentUser!.id}");
    print("¿Son iguales?: ${_item!.userId == _currentUser!.id}");
    
    // Intentamos convertir a string para ver si hay diferencia de tipos
    print("Comparación como strings: ${_item!.userId.toString() == _currentUser!.id.toString()}");
    
    return _item!.userId == _currentUser!.id;
  }

  // Verificar si el usuario actual puede eliminar el item
  bool _canDelete() {
    print("VERIFICANDO PERMISO DE BORRADO:");
    print("_currentUser es nulo: ${_currentUser == null}");
    
    if (_currentUser == null) {
      print("Usuario es nulo, retornando false");
      return false;
    }
    
    print("Es admin: ${_currentUser!.isAdmin}");
    print("Es propietario: ${_isOwner()}");
    print("Puede borrar: ${_currentUser!.isAdmin || _isOwner()}");
    
    return _currentUser!.isAdmin || _isOwner();
  }

  // Nuevos métodos para seleccionar fotos
  Future<void> _pickIdPhoto() async {
  try {
    await _showImageSourceDialog(
      title: 'Foto de Identificación',
      onCameraTap: () async {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        
        if (pickedFile != null) {
          setState(() {
            _idPhoto = File(pickedFile.path);
          });
        }
      },
      onGalleryTap: () async {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        
        if (pickedFile != null) {
          setState(() {
            _idPhoto = File(pickedFile.path);
          });
        }
      },
    );
  } catch (e) {
    print("Error picking ID photo: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al seleccionar la foto: ${e.toString()}')),
    );
  }
}

// Método actualizado para mostrar opciones al seleccionar foto de entrega
Future<void> _pickClaimPhoto() async {
  try {
    await _showImageSourceDialog(
      title: 'Foto de Entrega',
      onCameraTap: () async {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        
        if (pickedFile != null) {
          setState(() {
            _claimPhoto = File(pickedFile.path);
          });
        }
      },
      onGalleryTap: () async {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        
        if (pickedFile != null) {
          setState(() {
            _claimPhoto = File(pickedFile.path);
          });
        }
      },
    );
  } catch (e) {
    print("Error picking claim photo: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al seleccionar la foto: ${e.toString()}')),
    );
  }
}

Future<void> _showImageSourceDialog({
  required String title,
  required Function() onCameraTap,
  required Function() onGalleryTap,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Seleccionar $title'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Tomar foto'),
            onTap: () {
              Navigator.pop(context);
              onCameraTap();
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Elegir de la galería'),
            onTap: () {
              Navigator.pop(context);
              onGalleryTap();
            },
          ),
        ],
      ),
    ),
  );
}

  // Método actualizado para actualizar el estado
  /**
 * Actualiza el estado de un objeto perdido
 * @param {int} statusId - Nuevo estado a aplicar (1-4)
 */
Future<void> _updateStatus(int statusId) async {
  // Verificar precondiciones
  if (_item == null || !_isAdmin) {
    print("No se puede actualizar: item nulo o usuario no autorizado");
    return;
  }

  print("==== INICIANDO ACTUALIZACIÓN DE ESTADO ====");
  print("ID del objeto: ${_item!.id}");
  print("Estado actual: ${_item!.statusId}");
  print("Nuevo estado solicitado: $statusId");

  // Si es estado "claimed" (3), verificar las fotos y mostrar sección correspondiente
  if (statusId == 3) {
    // Si aún no se están mostrando los selectores de foto, mostrarlos
    if (!_showClaimSection) {
      setState(() {
        _showClaimSection = true;
      });
      
      // Mostrar mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor tome las fotos requeridas para la reclamación'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 4),
        ),
      );
      return; // No procesamos el cambio de estado todavía
    }
    
    // Verificar que ambas fotos estén seleccionadas
    if (_idPhoto == null || _claimPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debe proporcionar ambas fotos (DNI y entrega) para marcar como reclamado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Verificar que las fotos existan
    try {
      if (!await _idPhoto!.exists() || !await _claimPhoto!.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Una o ambas fotos no están disponibles. Por favor, tómelas nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      print("Error verificando existencia de archivos: $e");
    }
    
    // Pedir confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Reclamación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Está seguro de que desea marcar este objeto como reclamado?'),
            SizedBox(height: 12),
            Text(
              'Se subirán las fotos del DNI y de la entrega como comprobante.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
            child: Text('Confirmar'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
  }

  // Activar indicador de carga
  setState(() {
    _isUpdatingStatus = true;
  });

  try {
    print("Enviando solicitud de actualización al servidor...");
    print("Params: itemId=${_item!.id}, statusId=$statusId");
    
    if (statusId == 3) {
      print("Fotos: DNI=${_idPhoto?.path}, Entrega=${_claimPhoto?.path}");
    }
    
    // Usar la versión actualizada del método que permite enviar fotos
    final response = await _lostItemService.updateStatus(
      _item!.id, 
      statusId,
      idPhoto: statusId == 3 ? _idPhoto : null,
      claimPhoto: statusId == 3 ? _claimPhoto : null,
    );
    
    // Procesar respuesta
    if (response.success && response.data != null) {
      print("Estado actualizado exitosamente");
      
      setState(() {
        _item = response.data;
        // Limpiar fotos y resetear la UI
        _idPhoto = null;
        _claimPhoto = null;
        _showClaimSection = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print("Error en la respuesta: ${response.message}");
      if (response.error != null) {
        print("Detalles del error: ${response.error}");
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e, stackTrace) {
    print("Excepción durante la actualización: $e");
    print("Stack trace: $stackTrace");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error inesperado: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    // Desactivar indicador de carga
    setState(() {
      _isUpdatingStatus = false;
    });
  }
}

  Future<void> _deleteItem() async {
    // Verificamos que _item no sea nulo
    if (_item == null) return;

    // Utilizamos los métodos auxiliares para determinar los permisos
    final isOwner = _isOwner();
    final confirmationMessage = isOwner 
        ? '¿Estás seguro de que quieres eliminar tu publicación?' 
        : '¿Estás seguro de que quieres eliminar este objeto?';

    // Logs para depuración con operadores de acceso seguro
    print("Delete request - Is owner: $isOwner");
    print("Item user ID: ${_item?.userId}, Current user ID: ${_currentUser?.id}");

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar publicación'),
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
        print("Deleting item with ID: ${_item!.id}");
        final response = await _lostItemService.deleteLostItem(_item!.id);
        
        setState(() {
          _isLoading = false;
        });
        
        if (response.success) {
          // Mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOwner 
                  ? 'Tu publicación ha sido eliminada correctamente' 
                  : 'El objeto ha sido eliminado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Volver a la pantalla anterior
          Navigator.pop(context, true);
        } else {
          // Mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.message}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print("Error deleting item: $e");
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la publicación: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEPURACIÓN: Comprobar visibilidad de botones en cada rebuild
    print("BUILD STATE CHECK:");
    print("isOwner(): ${_isOwner()}");
    print("canDelete(): ${_canDelete()}");
    
    return BaseScreen(
      title: _item?.isFound == true ? 'Objeto encontrado' : 'Objeto Perdido',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadData,
      actions: _buildActions(),
      body: _item == null
          ? Container()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen con ruta corregida para lostitems
                    if (_item?.imageUrl != null && _item!.imageUrl!.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            // Corregido para usar el directorio correcto 'lostitems'
                            '${ApiConfig.uploadBaseUrl}/lostitems/${_item!.imageUrl}',
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
                              print("Error cargando imagen: $error");
                              print("URL de imagen: ${ApiConfig.uploadBaseUrl}/lostitems/${_item!.imageUrl}");
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
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
                        SizedBox(width: 8),
                        _buildTypeBadge(),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _item?.title ?? 'No Title',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _item?.description ?? 'No Description',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          _item?.locationDisplay ?? 'Unknown Location',
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
                            _item?.specificLocation ?? 'No specific location',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'Reportado por ${_item?.reporterName ?? 'Unknown'} (@${_item?.username ?? 'Unknown'})',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información de Contacto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(_item?.contactInfo ?? 'No contact information provided'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Sección de fotos de reclamación (visible solo si el objeto está reclamado)
                    if (_item?.statusId == 3 && _item?.hasClaimPhotos == true)
                      _buildClaimPhotosSection(),
                    
                    // Sección condicional original
                    if (_isOwner())
                      Card(
                        color: Colors.blue[50],
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Opciones del Propietario',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _deleteItem,
                                      icon: Icon(Icons.delete),
                                      label: Text('Eliminar mi publicación'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 16),
                    
                    // Selector de fotos para reclamación (solo para admin/staff y cuando quieren marcar como claimed)
                    if (_isAdmin && _showClaimSection)
                      _buildClaimPhotoSelectors(),
                      
                    if (_isAdmin) _buildStatusUpdateSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // Sección para mostrar fotos de reclamación
  Widget _buildClaimPhotosSection() {
    return Card(
      color: Colors.green[50],
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentación de Reclamo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'El objeto ha sido entregado a su propietario con la siguiente documentación:',
              style: TextStyle(
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 16),
            
            // Foto de DNI
            if (_item?.idPhotoUrl != null)
              _buildClaimImageView(
                'Identificación',
                '${ApiConfig.uploadBaseUrl}/lostitems/${_item!.idPhotoUrl}',
              ),
              
            SizedBox(height: 16),
              
            // Foto de entrega
            if (_item?.claimPhotoUrl != null)
              _buildClaimImageView(
                'Entrega del objeto',
                '${ApiConfig.uploadBaseUrl}/lostitems/${_item!.claimPhotoUrl}',
              ),
          ],
        ),
      ),
    );
  }
  
  // Widget para mostrar una imagen de reclamo
  Widget _buildClaimImageView(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                      : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print("Error cargando imagen de reclamación: $error");
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No se pudo cargar la imagen',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Sección de selectores de fotos para la reclamación
  // Actualización del _buildClaimPhotoSelectors() para enfatizar que son fotos tomadas en el momento
Widget _buildClaimPhotoSelectors() {
  return Card(
    color: Colors.amber[50],
    elevation: 2,
    margin: EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fotos Requeridas para Reclamación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Para marcar este objeto como reclamado, debe tomar las siguientes fotos:',
            style: TextStyle(color: Colors.amber[800]),
          ),
          SizedBox(height: 16),
          
          // Selector para la foto del DNI
          Card(
            elevation: 1,
            child: InkWell(
              onTap: _pickIdPhoto,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.amber[800]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tomar Foto de DNI',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Tome una foto del documento de identidad del reclamante',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _idPhoto != null
                        ? Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _idPhoto!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Material(
                                color: Colors.white.withOpacity(0.8),
                                shape: CircleBorder(),
                                child: InkWell(
                                  onTap: _pickIdPhoto,
                                  customBorder: CircleBorder(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(Icons.camera_alt, color: Colors.amber[800]),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Toque para tomar una foto del DNI',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Selector para la foto de entrega
          Card(
            elevation: 1,
            child: InkWell(
              onTap: _pickClaimPhoto,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.amber[800]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tomar Foto de Entrega',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Tome una foto del momento de entrega del objeto al reclamante',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _claimPhoto != null
                        ? Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _claimPhoto!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Material(
                                color: Colors.white.withOpacity(0.8),
                                shape: CircleBorder(),
                                child: InkWell(
                                  onTap: _pickClaimPhoto,
                                  customBorder: CircleBorder(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(Icons.camera_alt, color: Colors.amber[800]),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Toque para tomar una foto del momento de entrega',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showClaimSection = false;
                      _idPhoto = null;
                      _claimPhoto = null;
                    });
                  },
                  child: Text('Cancelar'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_idPhoto != null && _claimPhoto != null) 
                    ? () => _updateStatus(3) 
                    : null,
                  child: Text('Confirmar Reclamo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  List<Widget>? _buildActions() {
    // DEPURACIÓN: Imprimir información sobre por qué se muestra o no el botón
    print("CONSTRUYENDO ACCIONES:");
    print("_canDelete(): ${_canDelete()}");
    
    // Para depuración, siempre mostramos el botón
    final isOwner = _isOwner();
    
    print("Visibilidad de botón en acciones: true (forzado para depuración)");
    
    return [
      IconButton(
        icon: Icon(
          Icons.delete,
          color: isOwner ? Colors.red : Colors.orange,
        ),
        tooltip: isOwner ? 'Eliminar mi publicación' : 'Eliminar (depuración)',
        onPressed: _deleteItem,
      ),
    ];
  }

  Widget _buildStatusBadge() {
    if (_item == null) return Container();

    Color color;
    switch (_item!.statusId) {
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
        _item?.statusName ?? 'Unknown',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    if (_item == null) return Container();

    final color = _item!.isFound ? Colors.green : Colors.blue;
    final displayText = _item!.isFound ? 'Encontrado' : 'Perdido';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        displayText,
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
        padding: EdgeInsets.all(16),
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
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusButton(1, 'Pendiente', AppTheme.pendingColor),
                _buildStatusButton(2, 'Sotano D', AppTheme.inProgressColor),
                _buildStatusButton(3, 'Reclamado', AppTheme.resolvedColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(int statusId, String label, Color color) {
    final isSelected = _item?.statusId == statusId;
    final isDisabled = _isUpdatingStatus || 
                       (statusId == 3 && _showClaimSection) || 
                       isSelected == true;
                      
    return ElevatedButton(
      onPressed: isDisabled 
        ? null 
        : () => _updateStatus(statusId),
      child: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected == true ? Colors.grey : color,
        disabledBackgroundColor: isSelected == true ? color.withOpacity(0.7) : Colors.grey[400],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size(80, 30),
      ),
    );
  }
}