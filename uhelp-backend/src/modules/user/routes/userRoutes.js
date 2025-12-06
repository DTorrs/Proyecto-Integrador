// src/modules/user/routes/userRoutes.js
const express = require('express');
const { body } = require('express-validator');
const userController = require('../controllers/userController');
const { authenticateToken } = require('../../../middleware/auth');
const { profilesUpload } = require('../../../middleware/upload');

const router = express.Router();

// Get current user profile
router.get('/profile', authenticateToken, userController.getUserProfile);

// Get a specific user's profile
router.get('/profile/:id', authenticateToken, userController.getUserProfile);

// Update profile
router.put(
  '/profile',
  authenticateToken,
  profilesUpload('profilePicture'),
  [
    body('fullName')
      .optional()
      .isLength({ min: 2, max: 100 })
      .withMessage('Full name must be between 2 and 100 characters')
  ],
  userController.updateProfile
);

// Change password
router.put(
  '/change-password',
  authenticateToken,
  [
    body('currentPassword')
      .notEmpty()
      .withMessage('Current password is required'),
    
    body('newPassword')
      .isLength({ min: 6 })
      .withMessage('New password must be at least 6 characters long')
  ],
  userController.changePassword
);

// Get user activity
router.get('/activity', authenticateToken, userController.getUserActivity);

module.exports = router;