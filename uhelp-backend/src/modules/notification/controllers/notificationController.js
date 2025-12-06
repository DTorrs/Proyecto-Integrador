// src/modules/notification/controllers/notificationController.js
const notificationModel = require('../models/notificationModel');
const { createResponse, getPaginationParams, paginateResults } = require('../../../utils/helpers');

class NotificationController {
  /**
   * Get all notifications for the authenticated user
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getUserNotifications(req, res) {
    try {
      // Extract pagination parameters
      const { page, pageSize } = getPaginationParams(req.query);
      
      // Get unread only if requested
      const unreadOnly = req.query.unreadOnly === 'true';
      
      // Get user's notifications
      const notifications = await notificationModel.getUserNotifications(req.user.id, unreadOnly);
      
      // Paginate results
      const paginatedNotifications = paginateResults(notifications, page, pageSize);
      
      res.status(200).json(createResponse(true, 'Notifications retrieved', paginatedNotifications));
    } catch (error) {
      console.error('Get notifications error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Mark a notification as read
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async markAsRead(req, res) {
    try {
      const notificationId = req.params.id;
      const userId = req.user.id;
      
      // Mark notification as read
      const success = await notificationModel.markAsRead(notificationId, userId);
      
      if (!success) {
        return res.status(404).json(createResponse(false, 'Notification not found or already read'));
      }
      
      res.status(200).json(createResponse(true, 'Notification marked as read'));
    } catch (error) {
      console.error('Mark notification as read error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Mark all notifications as read for a user
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async markAllAsRead(req, res) {
    try {
      const userId = req.user.id;
      
      // Mark all notifications as read
      await notificationModel.markAllAsRead(userId);
      
      res.status(200).json(createResponse(true, 'All notifications marked as read'));
    } catch (error) {
      console.error('Mark all notifications as read error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Delete a notification
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async deleteNotification(req, res) {
    try {
      const notificationId = req.params.id;
      const userId = req.user.id;
      
      // Delete notification
      const success = await notificationModel.deleteNotification(notificationId, userId);
      
      if (!success) {
        return res.status(404).json(createResponse(false, 'Notification not found'));
      }
      
      res.status(200).json(createResponse(true, 'Notification deleted successfully'));
    } catch (error) {
      console.error('Delete notification error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
  
  /**
   * Get unread notification count
   * @param {object} req - Express request object
   * @param {object} res - Express response object
   */
  async getUnreadCount(req, res) {
    try {
      const userId = req.user.id;
      
      // Get unread notification count
      const count = await notificationModel.getUnreadCount(userId);
      
      res.status(200).json(createResponse(true, 'Unread notification count retrieved', { count }));
    } catch (error) {
      console.error('Get unread count error:', error);
      res.status(500).json(createResponse(false, 'Server error', null, error));
    }
  }
}

module.exports = new NotificationController();