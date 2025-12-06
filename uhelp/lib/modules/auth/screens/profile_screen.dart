import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/base_screen.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../config/api_config.dart';
import '../../../core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _imageFile;
  User? _user;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First try to get cached user
      final cachedUser = await _authService.getStoredUser();
      if (cachedUser != null) {
        setState(() {
          _user = cachedUser;
          _fullNameController.text = cachedUser.fullName;
        });
      }

      // Then fetch from API to get latest data
      final response = await _authService.getCurrentUser();
      if (response.success && response.data != null) {
        setState(() {
          _user = response.data;
          _fullNameController.text = response.data!.fullName;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile data';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        // Handle profile update
        final updateResponse = await _authService.updateProfile(
          _fullNameController.text.trim(),
        );

        if (updateResponse.success) {
          // Handle password change if requested
          if (_changePassword && _currentPasswordController.text.isNotEmpty) {
            final passwordResponse = await _authService.changePassword(
              _currentPasswordController.text,
              _newPasswordController.text,
            );

            if (passwordResponse.success) {
              setState(() {
                _successMessage = 'Profile and password updated successfully';
                _changePassword = false;
                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmPasswordController.clear();
              });
            } else {
              setState(() {
                _errorMessage = passwordResponse.message;
              });
            }
          } else {
            setState(() {
              _successMessage = 'Profile updated successfully';
            });
          }

          // Reload user data
          await _loadUserData();
        } else {
          setState(() {
            _errorMessage = updateResponse.message;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Perfil',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadUserData,
      body: _buildProfileForm(),
    );
  }

  Widget _buildProfileForm() {
    if (_user == null) {
      return Center(child: Text('No user data available'));
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: _user?.profilePicture != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        '${ApiConfig.uploadBaseUrl}/profiles/${_user!.profilePicture}',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          // Corregido: Verifica si fullName está vacío
                          _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      // Corregido: Verifica si fullName está vacío
                      _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              '@${_user!.username}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          Center(
            child: Text(
              _user!.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _user!.role,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_successMessage != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                _successMessage!,
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
          SizedBox(height: 24),
          Text(
            'Editar Perfil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          AppTextField(
            label: 'Nombre Completo',
            controller: _fullNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: _changePassword,
                onChanged: (value) {
                  setState(() {
                    _changePassword = value ?? false;
                  });
                },
              ),
              Text('Cambiar contraseña'),
            ],
          ),
          if (_changePassword) ...[
            SizedBox(height: 16),
            AppTextField(
              label: 'Contraseña Actual',
              controller: _currentPasswordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Nueva contraseña',
              controller: _newPasswordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Confirmar nueva contraseña',
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _updateProfile,
            child: Text('Guardar Cambios'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}