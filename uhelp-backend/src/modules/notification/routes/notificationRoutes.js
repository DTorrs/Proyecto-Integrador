// src/modules/notification/routes/notificationRoutes.js
const express = require('express');
const notificationController = require('../controllers/notificationController');
const { authenticateToken } = require('../../../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Get all notifications for the authenticated user
router.get('/', notificationController.getUserNotifications);

// Get unread notification count
router.get('/unread-count', notificationController.getUnreadCount);

// Mark a notification as read
router.put('/:id/read', notificationController.markAsRead);

// Mark all notifications as read
router.put('/mark-all-read', notificationController.markAllAsRead);

// Delete a notification
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;