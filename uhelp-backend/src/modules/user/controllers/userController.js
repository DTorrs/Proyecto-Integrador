// src/modules/user/controllers/userController.js
const { validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const userModel = require('../models/userModel');
const authModel = require('../../auth/models/authModel');
const { createResponse, deleteFile } = require('../../../utils/helpers');

class UserController {
  /**
   * Get user profile
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getUserProfile(req, res) {
    try {
      const userId = req.params.id || req.user.id;
      
      // Check if user exists
      const user = await userModel.getUserById(userId);
      if (!user) {
        return res.status(404).json(createResponse(false, 'User not found'));
      }
      
      // Return user profile
      res.status(200).json(createResponse(true, 'User profile retrieved', { user }));
    } catch (error) {
      console.error('Get user profile error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Update user profile
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async updateProfile(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const userId = req.user.id;
      const { fullName } = req.body;
      
      // Create update data object
      const updateData = {};
      if (fullName) updateData.fullName = fullName;
      
      // Add profile picture if uploaded
      if (req.file) {
        updateData.profilePicture = req.file.filename;
        
        // Get current user to delete old profile picture if exists
        const currentUser = await userModel.getUserById(userId);
        if (currentUser && currentUser.profile_picture) {
          await deleteFile(`profiles/${currentUser.profile_picture}`);
        }
      }
      
      // Update user profile
      const updatedUser = await userModel.updateUser(userId, updateData);
      
      res.status(200).json(createResponse(true, 'Profile updated successfully', { user: updatedUser }));
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Change user password
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async changePassword(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json(createResponse(false, 'Validation error', { errors: errors.array() }));
      }
      
      const userId = req.user.id;
      const { currentPassword, newPassword } = req.body;
      
      // Get user with password
      const user = await authModel.findUserByEmail(req.user.email);
      if (!user) {
        return res.status(404).json(createResponse(false, 'User not found'));
      }
      
      // Verify current password
      const isMatch = await bcrypt.compare(currentPassword, user.password);
      if (!isMatch) {
        return res.status(401).json(createResponse(false, 'Current password is incorrect'));
      }
      
      // Change password
      await userModel.changePassword(userId, newPassword);
      
      res.status(200).json(createResponse(true, 'Password changed successfully'));
    } catch (error) {
      console.error('Change password error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get user activity
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getUserActivity(req, res) {
    try {
      const userId = req.user.id;
      
      // Get user activity
      const activity = await userModel.getUserActivity(userId);
      
      res.status(200).json(createResponse(true, 'User activity retrieved', { activity }));
    } catch (error) {
      console.error('Get user activity error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new UserController();