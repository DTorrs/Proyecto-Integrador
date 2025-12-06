// src/modules/problem/models/problemModel.js
const { query, beginTransaction, commitTransaction, rollbackTransaction } = require('../../../database/connection');

class ProblemModel {
  /**
   * Create a new problem report
   * @param {object} problemData - Problem report data
   * @returns {Promise<object>} Newly created problem report
   */
  async createProblem(problemData) {
    try {
      const sql = `
        INSERT INTO problem_reports 
        (title, description, user_id, location_id, specific_location, category_id, image_url) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      
      const params = [
        problemData.title,
        problemData.description,
        problemData.userId,
        problemData.locationId,
        problemData.specificLocation,
        problemData.categoryId,
        problemData.imageUrl || null
      ];
      
      const result = await query(sql, params);
      
      // Return the newly created problem
      return await this.getProblemById(result.insertId);
    } catch (error) {
      console.error('Error creating problem:', error);
      throw error;
    }
  }
  
  /**
   * Get a problem report by ID
   * @param {number} problemId - Problem report ID
   * @returns {Promise<object|null>} Problem report or null if not found
   */
  async getProblemById(problemId) {
    try {
      const sql = `
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
        WHERE pr.id = ?
      `;
      
      const results = await query(sql, [problemId]);
      
      if (results.length === 0) {
        return null;
      }
      
      // Get comments for this problem
      const commentsSql = `
        SELECT rc.*, u.username, u.full_name
        FROM report_comments rc
        JOIN users u ON rc.user_id = u.id
        WHERE rc.report_id = ?
        ORDER BY rc.created_at
      `;
      
      const comments = await query(commentsSql, [problemId]);
      
      // Return problem with comments
      return {
        ...results[0],
        comments
      };
    } catch (error) {
      console.error('Error getting problem by ID:', error);
      throw error;
    }
  }
  
  /**
   * Get all problem reports with filtering options
   * @param {object} filters - Filter options
   * @returns {Promise<Array>} Array of problem reports
   */
  async getProblems(filters = {}) {
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
      if (filters.categoryId) {
        sql += ' AND pr.category_id = ?';
        params.push(filters.categoryId);
      }
      
      if (filters.statusId) {
        sql += ' AND pr.status_id = ?';
        params.push(filters.statusId);
      }
      
      if (filters.locationId) {
        sql += ' AND pr.location_id = ?';
        params.push(filters.locationId);
      }
      
      if (filters.userId) {
        sql += ' AND pr.user_id = ?';
        params.push(filters.userId);
      }
      
      // Order by - default to most recent
      let orderBy = 'pr.created_at DESC';
      
      if (filters.sortBy === 'votes') {
        orderBy = 'vote_count DESC, pr.created_at DESC';
      } else if (filters.sortBy === 'oldest') {
        orderBy = 'pr.created_at ASC';
      }
      
      sql += ` ORDER BY ${orderBy}`;
      
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
      console.error('Error getting problems:', error);
      throw error;
    }
  }
  
  /**
   * Update a problem report
   * @param {number} problemId - Problem report ID
   * @param {object} updateData - Data to update
   * @returns {Promise<object>} Updated problem report
   */
  async updateProblem(problemId, updateData) {
    try {
      // Build the SQL query dynamically based on provided fields
      let sql = 'UPDATE problem_reports SET ';
      const params = [];
      const fields = [];
      
      if (updateData.title) {
        fields.push('title = ?');
        params.push(updateData.title);
      }
      
      if (updateData.description) {
        fields.push('description = ?');
        params.push(updateData.description);
      }
      
      if (updateData.locationId) {
        fields.push('location_id = ?');
        params.push(updateData.locationId);
      }
      
      if (updateData.specificLocation) {
        fields.push('specific_location = ?');
        params.push(updateData.specificLocation);
      }
      
      if (updateData.categoryId) {
        fields.push('category_id = ?');
        params.push(updateData.categoryId);
      }
      
      if (updateData.statusId) {
        fields.push('status_id = ?');
        params.push(updateData.statusId);
      }
      
      if (updateData.imageUrl) {
        fields.push('image_url = ?');
        params.push(updateData.imageUrl);
      }
      
      // If no fields to update, return current problem
      if (fields.length === 0) {
        return await this.getProblemById(problemId);
      }
      
      // Complete the SQL query
      sql += fields.join(', ');
      sql += ' WHERE id = ?';
      params.push(problemId);
      
      // Execute the update query
      await query(sql, params);
      
      // Return the updated problem
      return await this.getProblemById(problemId);
    } catch (error) {
      console.error('Error updating problem:', error);
      throw error;
    }
  }
  
  /**
   * Delete a problem report
   * @param {number} problemId - Problem report ID
   * @returns {Promise<boolean>} Success status
   */
  async deleteProblem(problemId) {
    const connection = await beginTransaction();
    
    try {
      // Delete votes first (foreign key constraint)
      await connection.execute('DELETE FROM report_votes WHERE report_id = ?', [problemId]);
      
      // Delete comments (foreign key constraint)
      await connection.execute('DELETE FROM report_comments WHERE report_id = ?', [problemId]);
      
      // Delete the problem
      const [result] = await connection.execute('DELETE FROM problem_reports WHERE id = ?', [problemId]);
      
      await commitTransaction(connection);
      
      return result.affectedRows > 0;
    } catch (error) {
      await rollbackTransaction(connection);
      console.error('Error deleting problem:', error);
      throw error;
    }
  }
  
  /**
   * Update problem status
   * @param {number} problemId - Problem report ID
   * @param {number} statusId - New status ID
   * @returns {Promise<object>} Updated problem report
   */
  async updateStatus(problemId, statusId) {
    try {
      const sql = 'UPDATE problem_reports SET status_id = ? WHERE id = ?';
      await query(sql, [statusId, problemId]);
      
      return await this.getProblemById(problemId);
    } catch (error) {
      console.error('Error updating problem status:', error);
      throw error;
    }
  }
  
  /**
   * Add a vote to a problem report
   * @param {number} problemId - Problem report ID
   * @param {number} userId - User ID
   * @returns {Promise<object>} Vote count
   */
  async addVote(problemId, userId) {
    try {
      // Check if user has already voted
      const checkSql = 'SELECT id FROM report_votes WHERE report_id = ? AND user_id = ?';
      const existingVotes = await query(checkSql, [problemId, userId]);
      
      if (existingVotes.length > 0) {
        // User has already voted, so we'll remove their vote
        const deleteSql = 'DELETE FROM report_votes WHERE report_id = ? AND user_id = ?';
        await query(deleteSql, [problemId, userId]);
      } else {
        // User hasn't voted yet, add a vote
        const insertSql = 'INSERT INTO report_votes (report_id, user_id) VALUES (?, ?)';
        await query(insertSql, [problemId, userId]);
      }
      
      // Get updated vote count
      const countSql = 'SELECT COUNT(*) as vote_count FROM report_votes WHERE report_id = ?';
      const countResult = await query(countSql, [problemId]);
      
      return {
        voteCount: countResult[0].vote_count,
        userVoted: existingVotes.length === 0 // true if vote was added, false if removed
      };
    } catch (error) {
      console.error('Error voting on problem:', error);
      throw error;
    }
  }
  
  /**
   * Add a comment to a problem report
   * @param {number} problemId - Problem report ID
   * @param {number} userId - User ID
   * @param {string} comment - Comment text
   * @returns {Promise<object>} Created comment
   */
  async addComment(problemId, userId, comment) {
    try {
      const sql = 'INSERT INTO report_comments (report_id, user_id, comment) VALUES (?, ?, ?)';
      const result = await query(sql, [problemId, userId, comment]);
      
      // Get the created comment
      const commentSql = `
        SELECT rc.*, u.username, u.full_name
        FROM report_comments rc
        JOIN users u ON rc.user_id = u.id
        WHERE rc.id = ?
      `;
      
      const comments = await query(commentSql, [result.insertId]);
      
      return comments[0];
    } catch (error) {
      console.error('Error adding comment:', error);
      throw error;
    }
  }
  
  /**
   * Delete a comment
   * @param {number} commentId - Comment ID
   * @param {number} userId - User ID (for authorization)
   * @returns {Promise<boolean>} Success status
   */
  async deleteComment(commentId, userId) {
    try {
      // Check if user is the comment author
      const checkSql = 'SELECT user_id FROM report_comments WHERE id = ?';
      const comments = await query(checkSql, [commentId]);
      
      if (comments.length === 0) {
        return false; // Comment not found
      }
      
      // Check if the user is authorized to delete this comment
      if (comments[0].user_id !== userId) {
        // Check if user is an admin (role_id 3)
        const adminCheckSql = 'SELECT role_id FROM users WHERE id = ?';
        const users = await query(adminCheckSql, [userId]);
        
        if (users.length === 0 || users[0].role_id !== 3) {
          return false; // Not authorized
        }
      }
      
      // Delete the comment
      const deleteSql = 'DELETE FROM report_comments WHERE id = ?';
      const result = await query(deleteSql, [commentId]);
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error deleting comment:', error);
      throw error;
    }
  }
  
  /**
   * Check if a user has voted on a problem
   * @param {number} problemId - Problem report ID
   * @param {number} userId - User ID
   * @returns {Promise<boolean>} True if user has voted
   */
  async hasUserVoted(problemId, userId) {
    try {
      const sql = 'SELECT id FROM report_votes WHERE report_id = ? AND user_id = ?';
      const result = await query(sql, [problemId, userId]);
      
      return result.length > 0;
    } catch (error) {
      console.error('Error checking if user voted:', error);
      throw error;
    }
  }
  
  /**
   * Get all categories
   * @returns {Promise<Array>} Array of categories
   */
  async getCategories() {
    try {
      return await query('SELECT * FROM categories ORDER BY name');
    } catch (error) {
      console.error('Error getting categories:', error);
      throw error;
    }
  }
  
  /**
   * Get all statuses
   * @returns {Promise<Array>} Array of statuses
   */
  async getStatuses() {
    try {
      return await query('SELECT * FROM statuses ORDER BY id');
    } catch (error) {
      console.error('Error getting statuses:', error);
      throw error;
    }
  }
}

module.exports = new ProblemModel();