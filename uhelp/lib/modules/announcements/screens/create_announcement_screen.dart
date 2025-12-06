// lib/modules/announcements/screens/create_announcement_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/form_widgets.dart';
import '../services/announcement_service.dart';
import '../../../config/api_config.dart';
import 'package:image_picker/image_picker.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final int? announcementId; // If provided, we're editing an existing announcement

  const CreateAnnouncementScreen({Key? key, this.announcementId}) : super(key: key);

  @override
  _CreateAnnouncementScreenState createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  final AnnouncementService _announcementService = AnnouncementService();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  File? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.announcementId != null) {
      _loadAnnouncementData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncementData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _announcementService.getAnnouncementById(widget.announcementId!);
      if (response.success && response.data != null) {
        final announcement = response.data!;
        
        setState(() {
          _titleController.text = announcement.title;
          _contentController.text = announcement.content;
          _isActive = announcement.isActive;
          _startDate = announcement.startDate;
          _endDate = announcement.endDate;
          _existingImageUrl = announcement.imageUrl;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load announcement: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final isEditing = widget.announcementId != null;
        
        // Debug info
        print('Submitting announcement:');
        print('Title: ${_titleController.text.trim()}');
        print('Content length: ${_contentController.text.trim().length}');
        print('isActive: $_isActive');
        print('startDate: ${_startDate.toIso8601String()}');
        print('endDate: ${_endDate?.toIso8601String()}');
        print('Has image: ${_imageFile != null}');
        
        if (isEditing) {
          final response = await _announcementService.updateAnnouncement(
            announcementId: widget.announcementId!,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            isActive: _isActive,
            startDate: _startDate,
            endDate: _endDate,
            image: _imageFile,
          );
          
          if (response.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Announcement updated successfully')),
            );
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = 'Update error: ${response.message}';
              print('Error details: ${response.error}');
            });
          }
        } else {
          final response = await _announcementService.createAnnouncement(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            isActive: _isActive,
            startDate: _startDate,
            endDate: _endDate,
            image: _imageFile,
          );
          
          if (response.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Announcement created successfully')),
            );
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = 'Create error: ${response.message}';
              if (response.error != null) {
                // Display validation errors if available
                if (response.error is Map && response.error['errors'] != null) {
                  final errors = response.error['errors'] as List;
                  if (errors.isNotEmpty) {
                    _errorMessage = 'Validation error: ${errors.map((e) => e['msg']).join(', ')}';
                  }
                }
                print('Error details: ${response.error}');
              }
            });
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to submit announcement: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear end date
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(Duration(days: 7)),
      firstDate: _startDate,
      lastDate: _startDate.add(Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcementId != null;
    
    return BaseScreen(
      title: isEditing ? 'Editar Anuncio' : 'Crear Anuncio',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: isEditing ? _loadAnnouncementData : null,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              ),
            
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                hintText: 'Introduca título',
                border: OutlineInputBorder(),
              ),
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
            
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Contenido',
                hintText: 'Introduzca contenido',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter content';
                }
                if (value.length < 10) {
                  return 'Content must be at least 10 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Image picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imagen (Opcional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                '${ApiConfig.uploadBaseUrl}/announcements/$_existingImageUrl',
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
                                  print("Error loading image: $error");
                                  return Center(
                                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo_library),
                      label: Text('Select Image'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    if (_imageFile != null || _existingImageUrl != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                            _existingImageUrl = null;
                          });
                        },
                        icon: Icon(Icons.delete),
                        label: Text('Remove Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Active toggle
            SwitchListTile(
              title: Text(
                'Activo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text('Mostrar este anuncio a usuarios'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            
            SizedBox(height: 16),
            
            // Start Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha Inicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // End Date (Optional)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha Fin (Opcional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Sin fecha fin (permanente)',
                          style: TextStyle(fontSize: 16),
                        ),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                if (_endDate != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _endDate = null;
                      });
                    },
                    icon: Icon(Icons.clear),
                    label: Text('Clear end date'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 30),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnnouncement,
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEditing ? 'Actalizar Anuncio' : 'Crear Anuncio'),
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