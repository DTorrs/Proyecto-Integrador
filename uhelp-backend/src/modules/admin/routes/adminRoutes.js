// src/modules/admin/routes/adminRoutes.js
const express = require('express');
const { body } = require('express-validator');
const adminController = require('../controllers/adminController');
const { authenticateToken, isAdmin } = require('../../../middleware/auth');

const router = express.Router();

// All admin routes require authentication and admin privileges
router.use(authenticateToken);
router.use(isAdmin);

// Get dashboard statistics
router.get('/dashboard', adminController.getDashboardStats);

// User management
router.get('/users', adminController.getUsers);
router.get('/roles', adminController.getRoles);
router.put(
  '/users/:id/role',
  [
    body('roleId')
      .notEmpty()
      .withMessage('Role ID is required')
      .isInt()
      .withMessage('Role ID must be an integer')
  ],
  adminController.updateUserRole
);

// Problem management
router.get('/problems', adminController.getProblems);

// Lost item management
router.get('/lost-items', adminController.getLostItems);

// Activity logging
router.post(
  '/activity',
  [
    body('action')
      .notEmpty()
      .withMessage('Action is required')
      .isLength({ max: 255 })
      .withMessage('Action cannot exceed 255 characters'),
    
    body('entityType')
      .notEmpty()
      .withMessage('Entity type is required')
      .isLength({ max: 50 })
      .withMessage('Entity type cannot exceed 50 characters'),
    
    body('entityId')
      .notEmpty()
      .withMessage('Entity ID is required')
      .isInt()
      .withMessage('Entity ID must be an integer')
  ],
  adminController.logActivity
);

// Get activity logs
router.get('/activity-logs', adminController.getActivityLogs);

module.exports = router;