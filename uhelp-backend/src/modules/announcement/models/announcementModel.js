// src/modules/announcement/models/announcementModel.js
const { query } = require('../../../database/connection');

class AnnouncementModel {
  /**
   * Create a new announcement
   * @param {object} announcementData - Announcement data
   * @returns {Promise<object>} Newly created announcement
   */
  async createAnnouncement(announcementData) {
    try {
      const sql = `
        INSERT INTO announcements 
        (title, content, user_id, is_active, start_date, end_date, image_url) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      
      const params = [
        announcementData.title,
        announcementData.content,
        announcementData.userId,
        announcementData.isActive,
        announcementData.startDate,
        announcementData.endDate || null,
        announcementData.imageUrl || null
      ];
      
      const result = await query(sql, params);
      
      // Return the newly created announcement
      return await this.getAnnouncementById(result.insertId);
    } catch (error) {
      console.error('Error creating announcement:', error);
      throw error;
    }
  }
  
  /**
   * Get an announcement by ID
   * @param {number} announcementId - Announcement ID
   * @returns {Promise<object|null>} Announcement or null if not found
   */
  async getAnnouncementById(announcementId) {
    try {
      const sql = `
        SELECT a.*, u.username, u.full_name as creator_name
        FROM announcements a
        JOIN users u ON a.user_id = u.id
        WHERE a.id = ?
      `;
      
      const results = await query(sql, [announcementId]);
      
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      console.error('Error getting announcement by ID:', error);
      throw error;
    }
  }
  
  /**
   * Get all announcements with filtering options
   * @param {object} filters - Filter options
   * @returns {Promise<Array>} Array of announcements
   */
  async getAnnouncements(filters = {}) {
    try {
      let sql = `
        SELECT a.*, u.username, u.full_name as creator_name
        FROM announcements a
        JOIN users u ON a.user_id = u.id
        WHERE 1=1
      `;
      
      const params = [];
      
      // Apply filters
      if (filters.activeOnly) {
        const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
        sql += ' AND a.is_active = TRUE AND a.start_date <= ? AND (a.end_date IS NULL OR a.end_date >= ?)';
        params.push(now, now);
      }
      
      if (filters.userId) {
        sql += ' AND a.user_id = ?';
        params.push(filters.userId);
      }
      
      // Search by title or content
      if (filters.search) {
        sql += ' AND (a.title LIKE ? OR a.content LIKE ?)';
        params.push(`%${filters.search}%`, `%${filters.search}%`);
      }
      
      // Order by date (newest first)
      sql += ' ORDER BY a.start_date DESC';
      
      // Add limit and offset if needed
      if (filters.limit) {
        sql += ' LIMIT ?';
        params.push(parseInt(filters.limit));
        
        if (filters.offset) {
          sql += ' OFFSET ?';
          params.push(parseInt(filters.offset));
        }
      }
      
      return await query(sql, params);
    } catch (error) {
      console.error('Error getting announcements:', error);
      throw error;
    }
  }
  
  /**
   * Update an announcement
   * @param {number} announcementId - Announcement ID
   * @param {object} updateData - Data to update
   * @returns {Promise<object>} Updated announcement
   */
  async updateAnnouncement(announcementId, updateData) {
    try {
      // Build the SQL query dynamically based on provided fields
      let sql = 'UPDATE announcements SET ';
      const params = [];
      const fields = [];
      
      if (updateData.title) {
        fields.push('title = ?');
        params.push(updateData.title);
      }
      
      if (updateData.content) {
        fields.push('content = ?');
        params.push(updateData.content);
      }
      
      if (updateData.isActive !== undefined) {
        fields.push('is_active = ?');
        params.push(updateData.isActive);
      }
      
      if (updateData.startDate) {
        fields.push('start_date = ?');
        params.push(updateData.startDate);
      }
      
      if (updateData.endDate) {
        fields.push('end_date = ?');
        params.push(updateData.endDate);
      } else if (updateData.endDate === null) {
        fields.push('end_date = NULL');
      }
      
      if (updateData.imageUrl) {
        fields.push('image_url = ?');
        params.push(updateData.imageUrl);
      }
      
      // If no fields to update, return current announcement
      if (fields.length === 0) {
        return await this.getAnnouncementById(announcementId);
      }
      
      // Complete the SQL query
      sql += fields.join(', ');
      sql += ' WHERE id = ?';
      params.push(announcementId);
      
      // Execute the update query
      await query(sql, params);
      
      // Return the updated announcement
      return await this.getAnnouncementById(announcementId);
    } catch (error) {
      console.error('Error updating announcement:', error);
      throw error;
    }
  }
  
  /**
   * Delete an announcement
   * @param {number} announcementId - Announcement ID
   * @returns {Promise<boolean>} Success status
   */
  async deleteAnnouncement(announcementId) {
    try {
      const sql = 'DELETE FROM announcements WHERE id = ?';
      const result = await query(sql, [announcementId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error deleting announcement:', error);
      throw error;
    }
  }
  
  /**
   * Get active announcements
   * @returns {Promise<Array>} Array of active announcements
   */
  async getActiveAnnouncements() {
    try {
      const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
      
      const sql = `
        SELECT a.*, u.username, u.full_name as creator_name
        FROM announcements a
        JOIN users u ON a.user_id = u.id
        WHERE a.is_active = TRUE
          AND a.start_date <= ?
          AND (a.end_date IS NULL OR a.end_date >= ?)
        ORDER BY a.start_date DESC
      `;
      
      return await query(sql, [now, now]);
    } catch (error) {
      console.error('Error getting active announcements:', error);
      throw error;
    }
  }
}

module.exports = new AnnouncementModel();