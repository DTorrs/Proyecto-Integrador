import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/location_model.dart';
import '../services/problem_service.dart';
import '../../map/services/map_service.dart';

class CreateProblemScreen extends StatefulWidget {
  const CreateProblemScreen({Key? key}) : super(key: key);

  @override
  _CreateProblemScreenState createState() => _CreateProblemScreenState();
}

class _CreateProblemScreenState extends State<CreateProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specificLocationController = TextEditingController();
  
  final ProblemService _problemService = ProblemService();
  final MapService _mapService = MapService();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  List<Category> _categories = [];
  List<Location> _locations = [];
  
  int? _selectedCategoryId;
  int? _selectedLocationId;
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
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load categories
      final categoriesResponse = await _problemService.getCategories();
      if (categoriesResponse.success && categoriesResponse.data != null) {
        setState(() {
          _categories = categoriesResponse.data!;
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }

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

  Future<void> _submitProblem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final response = await _problemService.createProblem(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          locationId: _selectedLocationId!,
          specificLocation: _specificLocationController.text.trim(),
          categoryId: _selectedCategoryId!,
          image: _imageFile,
        );

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Problem reported successfully')),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = response.message;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to submit problem: ${e.toString()}';
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
      title: 'Reportar Problema',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadData,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              hint: 'Describe el problema en detalle',
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
              label: 'Ubicacion',
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
            AppDropdown<int>(
              label: 'Categoria',
              value: _selectedCategoryId ?? 0,
              items: _categories
                  .map((category) => DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
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
              onPressed: _isSubmitting ? null : _submitProblem,
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Enviar Reporte'),
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