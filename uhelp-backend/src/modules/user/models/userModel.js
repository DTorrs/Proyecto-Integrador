// src/modules/user/models/userModel.js
const { query } = require('../../../database/connection');
const bcrypt = require('bcryptjs');

class UserModel {
  /**
   * Get a user by their ID
   * @param {number} userId - User's ID
   * @returns {Promise<object|null>} User object or null if not found
   */
  async getUserById(userId) {
    try {
      const sql = `
        SELECT u.id, u.username, u.email, u.full_name, u.profile_picture, 
               u.created_at, u.updated_at, r.name as role
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.id = ?
      `;
      
      const results = await query(sql, [userId]);
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      console.error('Error getting user by ID:', error);
      throw error;
    }
  }

  /**
   * Update a user's profile
   * @param {number} userId - User's ID
   * @param {object} userData - User data to update
   * @returns {Promise<object>} Updated user
   */
  async updateUser(userId, userData) {
    try {
      // Build the SQL query dynamically based on provided fields
      let sql = 'UPDATE users SET ';
      const params = [];
      const fields = [];

      if (userData.fullName) {
        fields.push('full_name = ?');
        params.push(userData.fullName);
      }

      if (userData.profilePicture) {
        fields.push('profile_picture = ?');
        params.push(userData.profilePicture);
      }

      // Add other fields as needed
      
      // If no fields to update, return current user
      if (fields.length === 0) {
        return await this.getUserById(userId);
      }

      // Complete the SQL query
      sql += fields.join(', ');
      sql += ' WHERE id = ?';
      params.push(userId);

      // Execute the update query
      await query(sql, params);
      
      // Return the updated user
      return await this.getUserById(userId);
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
  }

  /**
   * Change a user's password
   * @param {number} userId - User's ID
   * @param {string} newPassword - New password
   * @returns {Promise<boolean>} Success status
   */
  async changePassword(userId, newPassword) {
    try {
      // Hash the new password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(newPassword, salt);
      
      // Update the password
      const sql = 'UPDATE users SET password = ? WHERE id = ?';
      const result = await query(sql, [hashedPassword, userId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error changing password:', error);
      throw error;
    }
  }

  /**
   * Get user activity (reports, lost items, etc.)
   * @param {number} userId - User's ID
   * @returns {Promise<object>} User activity
   */
  async getUserActivity(userId) {
    try {
      // Get problem reports created by user
      const problemsSql = `
        SELECT id, title, status_id, created_at
        FROM problem_reports
        WHERE user_id = ?
        ORDER BY created_at DESC
      `;
      const problems = await query(problemsSql, [userId]);
      
      // Get lost items created by user
      const lostItemsSql = `
        SELECT id, title, is_found, status_id, created_at
        FROM lost_items
        WHERE user_id = ?
        ORDER BY created_at DESC
      `;
      const lostItems = await query(lostItemsSql, [userId]);
      
      // Get report votes by user
      const votesSql = `
        SELECT rv.report_id, pr.title, rv.created_at
        FROM report_votes rv
        JOIN problem_reports pr ON rv.report_id = pr.id
        WHERE rv.user_id = ?
        ORDER BY rv.created_at DESC
      `;
      const votes = await query(votesSql, [userId]);
      
      // Get comments by user
      const commentsSql = `
        SELECT rc.id, rc.report_id, pr.title, rc.comment, rc.created_at
        FROM report_comments rc
        JOIN problem_reports pr ON rc.report_id = pr.id
        WHERE rc.user_id = ?
        ORDER BY rc.created_at DESC
      `;
      const comments = await query(commentsSql, [userId]);
      
      return {
        problems,
        lostItems,
        votes,
        comments
      };
    } catch (error) {
      console.error('Error getting user activity:', error);
      throw error;
    }
  }
}

module.exports = new UserModel();