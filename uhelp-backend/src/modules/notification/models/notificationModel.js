// src/modules/notification/models/notificationModel.js
const { query } = require('../../../database/connection');

class NotificationModel {
  /**
   * Create a new notification
   * @param {object} notificationData - Notification data
   * @returns {Promise<object>} Newly created notification
   */
  async createNotification(notificationData) {
    try {
      const sql = `
        INSERT INTO notifications 
        (user_id, title, message, related_type, related_id) 
        VALUES (?, ?, ?, ?, ?)
      `;
      
      const params = [
        notificationData.userId,
        notificationData.title,
        notificationData.message,
        notificationData.relatedType,
        notificationData.relatedId
      ];
      
      const result = await query(sql, params);
      
      // Return the newly created notification
      return await this.getNotificationById(result.insertId);
    } catch (error) {
      console.error('Error creating notification:', error);
      throw error;
    }
  }
  
  /**
   * Get a notification by ID
   * @param {number} notificationId - Notification ID
   * @returns {Promise<object|null>} Notification or null if not found
   */
  async getNotificationById(notificationId) {
    try {
      const sql = 'SELECT * FROM notifications WHERE id = ?';
      const results = await query(sql, [notificationId]);
      
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      console.error('Error getting notification by ID:', error);
      throw error;
    }
  }
  
  /**
   * Get all notifications for a user
   * @param {number} userId - User ID
   * @param {boolean} unreadOnly - Only fetch unread notifications
   * @returns {Promise<Array>} Array of notifications
   */
  async getUserNotifications(userId, unreadOnly = false) {
    try {
      let sql = 'SELECT * FROM notifications WHERE user_id = ?';
      const params = [userId];
      
      if (unreadOnly) {
        sql += ' AND is_read = FALSE';
      }
      
      sql += ' ORDER BY created_at DESC';
      
      return await query(sql, params);
    } catch (error) {
      console.error('Error getting user notifications:', error);
      throw error;
    }
  }
  
  /**
   * Mark a notification as read
   * @param {number} notificationId - Notification ID
   * @param {number} userId - User ID (for authorization)
   * @returns {Promise<boolean>} Success status
   */
  async markAsRead(notificationId, userId) {
    try {
      const sql = 'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?';
      const result = await query(sql, [notificationId, userId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      throw error;
    }
  }
  
  /**
   * Mark all notifications as read for a user
   * @param {number} userId - User ID
   * @returns {Promise<boolean>} Success status
   */
  async markAllAsRead(userId) {
    try {
      const sql = 'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE';
      const result = await query(sql, [userId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      throw error;
    }
  }
  
  /**
   * Delete a notification
   * @param {number} notificationId - Notification ID
   * @param {number} userId - User ID (for authorization)
   * @returns {Promise<boolean>} Success status
   */
  async deleteNotification(notificationId, userId) {
    try {
      const sql = 'DELETE FROM notifications WHERE id = ? AND user_id = ?';
      const result = await query(sql, [notificationId, userId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error deleting notification:', error);
      throw error;
    }
  }
  
  /**
   * Get unread notification count for a user
   * @param {number} userId - User ID
   * @returns {Promise<number>} Count of unread notifications
   */
  async getUnreadCount(userId) {
    try {
      const sql = 'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = FALSE';
      const result = await query(sql, [userId]);
      
      return result[0].count;
    } catch (error) {
      console.error('Error getting unread notification count:', error);
      throw error;
    }
  }
}

module.exports = new NotificationModel();