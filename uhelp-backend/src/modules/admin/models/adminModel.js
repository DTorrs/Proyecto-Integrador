// src/modules/admin/models/adminModel.js
const { query } = require('../../../database/connection');

class AdminModel {
  /**
   * Get admin dashboard statistics
   * @returns {Promise<object>} Dashboard statistics
   */
  async getDashboardStats() {
    try {
      // Get total users
      const userSql = 'SELECT COUNT(*) as count FROM users';
      const userResults = await query(userSql);
      const totalUsers = userResults[0].count;
      
      // Get total problems by status
      const problemSql = `
        SELECT s.name, COUNT(*) as count 
        FROM problem_reports pr
        JOIN statuses s ON pr.status_id = s.id
        GROUP BY pr.status_id, s.name
      `;
      const problemResults = await query(problemSql);
      
      // Get total lost items by type and status
      const lostItemSql = `
        SELECT 
          is_found, 
          lis.name as status, 
          COUNT(*) as count 
        FROM lost_items li
        JOIN lost_item_statuses lis ON li.status_id = lis.id
        GROUP BY li.is_found, li.status_id, lis.name
      `;
      const lostItemResults = await query(lostItemSql);
      
      // Get problems by category
      const categorySql = `
        SELECT c.name, COUNT(*) as count 
        FROM problem_reports pr
        JOIN categories c ON pr.category_id = c.id
        GROUP BY pr.category_id, c.name
      `;
      const categoryResults = await query(categorySql);
      
      // Get problems by location
      const locationSql = `
        SELECT l.code, l.name, COUNT(*) as count 
        FROM problem_reports pr
        JOIN locations l ON pr.location_id = l.id
        GROUP BY pr.location_id, l.code, l.name
      `;
      const locationResults = await query(locationSql);
      
      // Get recent activity
      const activitySql = `
        SELECT al.id, al.action, al.entity_type, al.entity_id, 
               al.created_at, u.username, u.full_name
        FROM activity_logs al
        JOIN users u ON al.user_id = u.id
        ORDER BY al.created_at DESC
        LIMIT 10
      `;
      const activityResults = await query(activitySql);
      
      return {
        totalUsers,
        problems: {
          byStatus: problemResults,
          byCategory: categoryResults,
          byLocation: locationResults
        },
        lostItems: lostItemResults,
        recentActivity: activityResults
      };
    } catch (error) {
      console.error('Error getting dashboard stats:', error);
      throw error;
    }
  }
  
  /**
   * Get all users with pagination and search
   * @param {object} options - Search and pagination options
   * @returns {Promise<Array>} Array of users
   */
  async getUsers(options = {}) {
    try {
      let sql = `
        SELECT u.id, u.username, u.email, u.full_name, 
               u.profile_picture, u.created_at, r.name as role
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE 1=1
      `;
      
      const params = [];
      
      // Add search filter if provided
      if (options.search) {
        sql += ' AND (u.username LIKE ? OR u.email LIKE ? OR u.full_name LIKE ?)';
        params.push(`%${options.search}%`, `%${options.search}%`, `%${options.search}%`);
      }
      
      // Add role filter if provided
      if (options.roleId) {
        sql += ' AND u.role_id = ?';
        params.push(options.roleId);
      }
      
      // Add order by
      sql += ' ORDER BY u.created_at DESC';
      
      // Add limit and offset if provided
      if (options.limit) {
        sql += ' LIMIT ?';
        params.push(parseInt(options.limit));
        
        if (options.offset) {
          sql += ' OFFSET ?';
          params.push(parseInt(options.offset));
        }
      }
      
      return await query(sql, params);
    } catch (error) {
      console.error('Error getting users:', error);
      throw error;
    }
  }
  
  /**
   * Get problem reports for admin management
   * @param {object} options - Search and filter options
   * @returns {Promise<Array>} Array of problem reports
   */
  async getProblems(options = {}) {
    try {
      let sql = `
        SELECT pr.*, 
               u.username, u.full_name as reporter_name,
               l.code as location_code, l.name as location_name,
               c.name as category_name,
               s.name as status_name,
               (SELECT COUNT(*) FROM report_votes WHERE report_id = pr.id) as vote_count
        FROM problem_reports pr
        JOIN users u ON pr.user_id = u.id
        JOIN locations l ON pr.location_id = l.id
        JOIN categories c ON pr.category_id = c.id
        JOIN statuses s ON pr.status_id = s.id
        WHERE 1=1
      `;
      
      const params = [];
      
      // Apply filters
      if (options.statusId) {
        sql += ' AND pr.status_id = ?';
        params.push(options.statusId);
      }
      
      if (options.categoryId) {
        sql += ' AND pr.category_id = ?';
        params.push(options.categoryId);
      }
      
      if (options.locationId) {
        sql += ' AND pr.location_id = ?';
        params.push(options.locationId);
      }
      
      if (options.search) {
        sql += ' AND (pr.title LIKE ? OR pr.description LIKE ?)';
        params.push(`%${options.search}%`, `%${options.search}%`);
      }
      
      // Add order by
      if (options.sortBy === 'votes') {
        sql += ' ORDER BY vote_count DESC, pr.created_at DESC';
      } else if (options.sortBy === 'oldest') {
        sql += ' ORDER BY pr.created_at ASC';
      } else {
        sql += ' ORDER BY pr.created_at DESC';
      }
      
      // Add limit and offset if provided
      if (options.limit) {
        sql += ' LIMIT ?';
        params.push(parseInt(options.limit));
        
        if (options.offset) {
          sql += ' OFFSET ?';
          params.push(parseInt(options.offset));
        }
      }
      
      return await query(sql, params);
    } catch (error) {
      console.error('Error getting problems for admin:', error);
      throw error;
    }
  }
  
  /**
   * Get lost items for admin management
   * @param {object} options - Search and filter options
   * @returns {Promise<Array>} Array of lost items
   */
  async getLostItems(options = {}) {
    try {
      let sql = `
        SELECT li.*, 
               u.username, u.full_name as reporter_name,
               l.code as location_code, l.name as location_name,
               lis.name as status_name
        FROM lost_items li
        JOIN users u ON li.user_id = u.id
        JOIN locations l ON li.location_id = l.id
        JOIN lost_item_statuses lis ON li.status_id = lis.id
        WHERE 1=1
      `;
      
      const params = [];
      
      // Apply filters
      if (options.statusId) {
        sql += ' AND li.status_id = ?';
        params.push(options.statusId);
      }
      
      if (options.isFound !== undefined) {
        sql += ' AND li.is_found = ?';
        params.push(options.isFound);
      }
      
      if (options.locationId) {
        sql += ' AND li.location_id = ?';
        params.push(options.locationId);
      }
      
      if (options.search) {
        sql += ' AND (li.title LIKE ? OR li.description LIKE ?)';
        params.push(`%${options.search}%`, `%${options.search}%`);
      }
      
      // Add order by (most recent first)
      sql += ' ORDER BY li.created_at DESC';
      
      // Add limit and offset if provided
      if (options.limit) {
        sql += ' LIMIT ?';
        params.push(parseInt(options.limit));
        
        if (options.offset) {
          sql += ' OFFSET ?';
          params.push(parseInt(options.offset));
        }
      }
      
      return await query(sql, params);
    } catch (error) {
      console.error('Error getting lost items for admin:', error);
      throw error;
    }
  }
  
  /**
   * Log an admin activity
   * @param {object} activityData - Activity data
   * @returns {Promise<object>} Created activity log
   */
  async logActivity(activityData) {
    try {
      const sql = `
        INSERT INTO activity_logs 
        (user_id, action, entity_type, entity_id, details) 
        VALUES (?, ?, ?, ?, ?)
      `;
      
      const params = [
        activityData.userId,
        activityData.action,
        activityData.entityType,
        activityData.entityId,
        activityData.details || null
      ];
      
      const result = await query(sql, params);
      
      return {
        id: result.insertId,
        ...activityData
      };
    } catch (error) {
      console.error('Error logging activity:', error);
      throw error;
    }
  }
  
  /**
   * Update a user's role
   * @param {number} userId - User ID
   * @param {number} roleId - Role ID
   * @returns {Promise<boolean>} Success status
   */
  async updateUserRole(userId, roleId) {
    try {
      const sql = 'UPDATE users SET role_id = ? WHERE id = ?';
      const result = await query(sql, [roleId, userId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error updating user role:', error);
      throw error;
    }
  }
  
  /**
   * Get all roles
   * @returns {Promise<Array>} Array of roles
   */
  async getRoles() {
    try {
      return await query('SELECT * FROM roles ORDER BY id');
    } catch (error) {
      console.error('Error getting roles:', error);
      throw error;
    }
  }
  
  /**
   * Get activity logs with filters
   * @param {object} options - Filter options
   * @returns {Promise<Array>} Array of activity logs
   */
  async getActivityLogs(options = {}) {
    try {
      let sql = `
        SELECT al.*, u.username, u.full_name
        FROM activity_logs al
        JOIN users u ON al.user_id = u.id
        WHERE 1=1
      `;
      
      const params = [];
      
      // Apply filters
      if (options.userId) {
        sql += ' AND al.user_id = ?';
        params.push(options.userId);
      }
      
      if (options.entityType) {
        sql += ' AND al.entity_type = ?';
        params.push(options.entityType);
      }
      
      if (options.startDate) {
        sql += ' AND al.created_at >= ?';
        params.push(options.startDate);
      }
      
      if (options.endDate) {
        sql += ' AND al.created_at <= ?';
        params.push(options.endDate);
      }
      
      // Add order by (most recent first)
      sql += ' ORDER BY al.created_at DESC';
      
      // Add limit and offset if provided
      if (options.limit) {
        sql += ' LIMIT ?';
        params.push(parseInt(options.limit));
        
        if (options.offset) {
          sql += ' OFFSET ?';
          params.push(parseInt(options.offset));
        }
      }
      
      return await query(sql, params);
    } catch (error) {
      console.error('Error getting activity logs:', error);
      throw error;
    }
  }
}

module.exports = new AdminModel();