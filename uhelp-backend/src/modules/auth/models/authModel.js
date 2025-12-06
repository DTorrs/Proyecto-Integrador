// src/modules/auth/models/authModel.js
const { query } = require('../../../database/connection');
const bcrypt = require('bcryptjs');

class AuthModel {
  /**
   * Find a user by their email
   * @param {string} email - User's email address
   * @returns {Promise<object|null>} User object or null if not found
   */
  async findUserByEmail(email) {
    try {
      const sql = 'SELECT * FROM users WHERE email = ?';
      const results = await query(sql, [email]);
      
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      console.error('Error finding user by email:', error);
      throw error;
    }
  }
  
  /**
   * Find a user by their username
   * @param {string} username - User's username
   * @returns {Promise<object|null>} User object or null if not found
   */
  async findUserByUsername(username) {
    try {
      const sql = 'SELECT * FROM users WHERE username = ?';
      const results = await query(sql, [username]);
      
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      console.error('Error finding user by username:', error);
      throw error;
    }
  }
  
  /**
   * Create a new user
   * @param {object} userData - User data
   * @returns {Promise<object>} Newly created user
   */
  async createUser(userData) {
    try {
      // Hash the password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(userData.password, salt);
      
      // Insert the new user
      const sql = `
        INSERT INTO users (username, email, password, full_name, role_id) 
        VALUES (?, ?, ?, ?, ?)
      `;
      
      const result = await query(sql, [
        userData.username,
        userData.email,
        hashedPassword,
        userData.fullName,
        userData.roleId || 1  // Default to student role if not provided
      ]);
      
      // Fetch the created user (excluding the password)
      const newUser = await this.getUserById(result.insertId);
      return newUser;
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }
  
  /**
   * Get a user by their ID (excluding password)
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
   * Validate user credentials
   * @param {string} email - User's email
   * @param {string} password - User's password
   * @returns {Promise<object|null>} User object if valid, null otherwise
   */
  async validateCredentials(email, password) {
    try {
      // Get user by email
      const user = await this.findUserByEmail(email);
      
      if (!user) {
        return null;
      }
      
      // Compare passwords
      const isPasswordValid = await bcrypt.compare(password, user.password);
      
      if (!isPasswordValid) {
        return null;
      }
      
      // Return user without password
      const { password: _, ...userWithoutPassword } = user;
      return userWithoutPassword;
    } catch (error) {
      console.error('Error validating credentials:', error);
      throw error;
    }
  }
}

module.exports = new AuthModel();