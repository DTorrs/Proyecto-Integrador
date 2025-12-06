import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/models/location_model.dart';
import '../services/lost_item_service.dart';
import '../../map/services/map_service.dart';

class CreateLostItemScreen extends StatefulWidget {
  const CreateLostItemScreen({Key? key}) : super(key: key);

  @override
  _CreateLostItemScreenState createState() => _CreateLostItemScreenState();
}

class _CreateLostItemScreenState extends State<CreateLostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specificLocationController = TextEditingController();
  final _contactInfoController = TextEditingController();
  
  final LostItemService _lostItemService = LostItemService();
  final MapService _mapService = MapService();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  List<Location> _locations = [];
  
  int? _selectedLocationId;
  bool _isFound = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _specificLocationController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load locations
      final locationsResponse = await _mapService.getLocations();
      if (locationsResponse.success && locationsResponse.data != null) {
        setState(() {
          _locations = locationsResponse.data!;
          if (_locations.isNotEmpty) {
            _selectedLocationId = _locations.first.id;
          }
        });
      }
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

  Future<void> _submitItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final response = await _lostItemService.createLostItem(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          locationId: _selectedLocationId!,
          specificLocation: _specificLocationController.text.trim(),
          isFound: _isFound,
          contactInfo: _contactInfoController.text.trim(),
          image: _imageFile,
        );

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item reported successfully')),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = response.message;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to submit item: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Reportar Objetos Perdidos',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadData,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Objeto perdido'),
                    selected: !_isFound,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isFound = false;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Objeto Encontrado'),
                    selected: _isFound,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isFound = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Titulo',
              hint: 'Titulo del problema',
              controller: _titleController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Descripción',
              hint: 'Describe el objeto perdido',
              controller: _descriptionController,
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            AppDropdown<int>(
              label: 'Ubicación',
              value: _selectedLocationId ?? 0,
              items: _locations
                  .map((location) => DropdownMenuItem<int>(
                        value: location.id,
                        child: Text('${location.code}: ${location.name}'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a location';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Ubicación Específica',
              hint: 'Detalles de ubicación exacta',
              controller: _specificLocationController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a specific location';
                }
                if (value.length < 3) {
                  return 'Specific location must be at least 3 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Información de Contacto',
              hint: '¿Cómo otros pueden contactarte?',
              controller: _contactInfoController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digita información de contacto';
                }
                if (value.length < 5) {
                  return 'Contact information must be at least 5 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            ImagePickerWidget(
              label: 'Foto (Opcional)',
              imageFile: _imageFile,
              onImagePicked: (file) {
                setState(() {
                  _imageFile = file;
                });
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitItem,
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Enviar ${_isFound ? 'Encontrado' : 'Perdido'} Objeto'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}