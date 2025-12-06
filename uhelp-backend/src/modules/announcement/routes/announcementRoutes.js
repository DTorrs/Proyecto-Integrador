// src/modules/announcement/routes/announcementRoutes.js
const express = require('express');
const { body } = require('express-validator');
const announcementController = require('../controllers/announcementController');
const { authenticateToken, isStaffOrAdmin } = require('../../../middleware/auth');
const { announcementsUpload } = require('../../../middleware/upload');

const router = express.Router();

// Get all announcements (with optional filters)
router.get('/', announcementController.getAnnouncements);

// Get active announcements
router.get('/active', announcementController.getActiveAnnouncements);

// Get announcement by ID
router.get('/:id', announcementController.getAnnouncement);

// The following routes require authentication and staff/admin privileges
router.use(authenticateToken);
router.use(isStaffOrAdmin);

// Create a new announcement
router.post(
  '/',
  announcementsUpload('image'),
  [
    body('title')
      .notEmpty()
      .withMessage('Title is required')
      .isLength({ min: 5, max: 255 })
      .withMessage('Title must be between 5 and 255 characters'),
    
    body('content')
      .notEmpty()
      .withMessage('Content is required')
      .isLength({ min: 10 })
      .withMessage('Content must be at least 10 characters'),
    
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
    
    body('startDate')
      .optional()
      .isISO8601()
      .withMessage('Start date must be a valid date'),
    
    body('endDate')
      .optional()
      .isISO8601()
      .withMessage('End date must be a valid date')
      .custom((value, { req }) => {
        if (!value) return true;
        const startDate = req.body.startDate ? new Date(req.body.startDate) : new Date();
        const endDate = new Date(value);
        if (endDate <= startDate) {
          throw new Error('End date must be after start date');
        }
        return true;
      })
  ],
  announcementController.createAnnouncement
);

// Update an announcement
router.put(
  '/:id',
  announcementsUpload('image'),
  [
    body('title')
      .optional()
      .isLength({ min: 5, max: 255 })
      .withMessage('Title must be between 5 and 255 characters'),
    
    body('content')
      .optional()
      .isLength({ min: 10 })
      .withMessage('Content must be at least 10 characters'),
    
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
    
    body('startDate')
      .optional()
      .isISO8601()
      .withMessage('Start date must be a valid date'),
    
    body('endDate')
      .optional()
      .isISO8601()
      .withMessage('End date must be a valid date')
      .custom((value, { req }) => {
        if (!value) return true;
        let startDate;
        if (req.body.startDate) {
          startDate = new Date(req.body.startDate);
        } else {
          // If startDate is not provided in the update, we need to get the current value
          // This would require middleware to load the announcement first
          // For simplicity, we're just checking the provided endDate against current date
          startDate = new Date();
        }
        const endDate = new Date(value);
        if (endDate <= startDate) {
          throw new Error('End date must be after start date');
        }
        return true;
      })
  ],
  announcementController.updateAnnouncement
);

// Delete an announcement
router.delete('/:id', announcementController.deleteAnnouncement);

module.exports = router;